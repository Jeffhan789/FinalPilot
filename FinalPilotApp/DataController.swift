import CoreData
import SwiftUI

// MARK: - DataController

// MARK: [原理] NSPersistentContainer 单例模式
// [原理] Core Data 的 NSPersistentContainer 是重量级对象（初始化需加载模型文件、创建 SQLite 连接、配置线程队列）。
//        如果每次用都创建新实例，会导致：1) 内存重复分配；2) 数据库连接数暴涨；3) 多上下文写入冲突。
//        单例模式确保整个 App 生命周期内只有一个容器实例，所有 NSManagedObjectContext 都指向同一持久化栈。
// [面试] "为什么不用 @StateObject 或 @ObservedObject 管理 DataController？"
//        答：DataController 是基础设施层，SwiftUI 的 View 生命周期可能频繁重建。将容器绑定到 View 状态对象会导致：
//        1) 切换视图时容器可能意外释放；2) 多个 View 各持一个容器造成多实例冲突。单例由类自身持有，
//        与 View 生命周期解耦，是 Core Data 容器管理的标准做法。但要注意多线程问题：单例的 viewContext 是主线程上下文，
//        后台写入必须使用 newBackgroundContext()。
/// 管理 Core Data 持久化容器的单例控制器。
/// 提供 viewContext、后台上下文、自动保存和 SwiftUI 预览支持。
final class DataController: ObservableObject {
    // MARK: [原理] 单例的 `static let shared` 是线程安全的延迟初始化
    // [原理] Swift 的 `static let` 由运行时自动保证线程安全（内部使用 dispatch_once 语义），无需手动加锁。
    //        相比 `static var shared: DataController!` 的强制解包方案，`let` 不可变性更安全，避免运行时被篡改。
    // [面试] "Swift 单例有几种写法？线程安全如何保证？"
    //        答：三种主流写法：1) `static let`（最推荐，运行时自动线程安全，延迟初始化）；
    //        2) `static var` + `dispatch_once`（Objective-C 迁移模式，已废弃）；
    //        3) 全局常量（`let shared = DataController()`），不封装在类内，缺乏命名空间保护。
    //        本方案用 `static let shared = DataController()`，编译器会生成 `dispatch_once` 等价的线程安全屏障。
    static let shared = DataController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: [原理] 依赖注入的 `inMemory` 参数实现同一套代码支持两种运行模式
    // [原理] `inMemory: true` 时将持久化存储 URL 设为 `/dev/null`，SQLite 的写入实际上被黑洞丢弃，
    //        重启后数据消失。这是 SwiftUI 预览和单元测试的常用技巧——不需要清理数据库文件，也不会污染真实数据。
    //        `NSPersistentStoreDescription` 决定存储后端（SQLite、Binary、In-Memory），本例只修改 URL 即可切换。
    // [面试] "如何为 SwiftUI Preview 提供干净的 Core Data 数据？"
    //        答：核心思路是让 Container 支持 `inMemory` 模式。步骤：1) 初始化时检测 `inMemory` 参数；
    //        2) 将 `persistentStoreDescriptions.first?.url` 设为 `/dev/null`；3) 预览实例调用 `migrateSeedDataIfNeeded` 注入种子数据。
    //        优点：预览和真实环境共享同一套业务逻辑，无需维护两套代码。缺点：内存数据量大时可能不适合 `/dev/null` 方案，
    //        应考虑独立的内存存储描述（`NSPersistentStoreDescription(url: .init(fileURLWithPath: "/dev/null"))` 并设置 `type` 为 `NSInMemoryStoreType`）。
    init(inMemory: Bool = false) {
        // MARK: [原理] ValueTransformer 的注册必须在 NSPersistentContainer 初始化之前完成
        // [原理] Core Data 的 Transformable 属性在加载模型时就需要知道如何转换非标准类型（如 [String]）。
        //        ValueTransformer 是 Objective-C 运行时机制，基于 `NSValueTransformerName` 全局注册表。
        //        如果容器已经加载了模型，再注册 Transformer 会导致已加载的属性无法识别转换器，读取时返回 nil 或崩溃。
        //        注册调用 `setValueTransformer(_:forName:)` 本质是向全局字典插入 key-value，不是线程安全的，
        //        但 Swift 的 `static let` 单例初始化自带屏障，保证了注册和容器创建的顺序性。
        // [面试] "Core Data 怎么存储 [String] 数组？有什么坑？"
        //        答：有三种方案：1) Transformable + ValueTransformer（最灵活，适合复杂对象，但无法做 SQL 查询过滤）；
        //        2) 单独建 Entity 做一对多关系（可查询，但模型复杂）；3) 用逗号拼接存 String（最简单，但无类型安全）。
        //        本方案用方案 1：自定义 `StringArrayTransformer` 继承 `ValueTransformer`，将 [String] ↔ Data 通过 JSONEncoder 转换。
        //        坑：必须在 `NSPersistentContainer` 初始化**之前**注册，否则模型加载时找不到 Transformer；另外 Transformable 属性
        //        无法用在 NSPredicate 的查询条件中（因为数据库里存的是二进制 Data，不是结构化数据）。
        // 注册自定义 Value Transformer（用于 [String] Transformable 属性）
        ValueTransformer.setValueTransformer(
            StringArrayTransformer(),
            forName: NSValueTransformerName("StringArrayTransformer")
        )

        container = NSPersistentContainer(name: "FinalPilot")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                // MARK: [原理] Core Data 加载失败调用 fatalError 是合理的兜底策略
                // [原理] 持久化存储加载失败意味着整个 App 的数据层无法工作，继续运行会导致后续所有操作崩溃或数据丢失。
                //        `fatalError` 在 Release 环境下会直接终止进程，给用户明确的错误信号，避免在不可恢复状态下运行。
                //        更优雅的方案是：在加载回调中通过 Notification 通知 UI 层显示错误页，引导用户尝试修复或重装。
                // [面试] "Core Data 加载失败时你会怎么处理？"
                //        答：分场景。开发阶段用 `fatalError` 快速暴露问题。生产环境应：1) 捕获错误详情并上报（如 Firebase Crashlytics）；
                //        2) 尝试自动迁移或降级到内存模式；3) 如果都失败，展示用户友好的错误页面，提示"数据异常，建议重启或重装"，
                //        而不是直接崩溃。因为数据损坏可能是用户设备存储问题，直接崩溃会影响 App Store 评分。
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        // MARK: [原理] automaticallyMergesChangesFromParent 解决父子上下文数据同步问题
        // [原理] Core Data 的上下文是**工作副本**（working copy），`viewContext`（主线程）和后台上下文可以共享同一个持久化协调器（NSPersistentStoreCoordinator）。
        //        当后台上下文保存后，持久化存储中的数据已更新，但 `viewContext` 内存中的对象还是旧版本。
        //        `automaticallyMergesChangesFromParent = true` 让 `viewContext` 自动监听父级（persistentStoreCoordinator）的保存通知，
        //        自动合并变更，无需手动调用 `mergeChanges(fromContextDidSave:)`。
        // [面试] "后台线程更新了 Core Data，UI 怎么刷新？"
        //        答：两种方式。1) 自动合并：`viewContext.automaticallyMergesChangesFromParent = true`，这是最推荐的做法，
        //        简洁且无遗漏。2) 手动合并：在后台上下文保存后发送通知，`viewContext.mergeChanges(fromContextDidSave: notification)`，
        //        适合需要精细控制合并时机的场景（如合并前做数据校验）。注意：自动合并只在父子上下文关系中生效，
        //        如果两个上下文是独立的（各自关联不同的 NSPersistentStoreCoordinator），则不会自动合并。
        container.viewContext.automaticallyMergesChangesFromParent = true

        // MARK: [原理] mergeByPropertyObjectTrump 的合并策略选择
        // [原理] Core Data 上下文合并时可能遇到冲突：内存中的对象和数据库中的对象同一属性值不同。
        //        `mergeByPropertyObjectTrump` 的策略是：以内存对象（object）的属性值为准，覆盖数据库中的值（"Trump" 即"胜出"）。
        //        对应策略：`mergeByPropertyStoreTrump` 以数据库为准。选择 objectTrump 是因为：用户当前界面的编辑状态是最新的，
        //        不应被后台同步或其他线程的写入覆盖。但如果后台任务执行了批量更新（如服务器同步），则应该用 storeTrump。
        // [面试] "Core Data 的 mergePolicy 有几种？你怎么选？"
        //        答：四种标准策略：1) `error`（遇到冲突就报错，最不实用）；2) `mergeByPropertyObjectTrump`（内存优先，适合用户编辑场景）；
        //        3) `mergeByPropertyStoreTrump`（数据库优先，适合服务器同步覆盖本地）；4) `overwrite`（整对象覆盖，不区分属性）。
        //        还可以自定义 `NSMergePolicy` 子类实现自定义逻辑。本 App 选择 objectTrump 因为：用户正在操作的数据是最权威的，
        //        后台任务（如 Widget 同步、通知调度）的写入不应该覆盖用户的主动编辑。
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        registerAutoSave()
    }

    // MARK: [原理] 后台上下文必须独立创建，不能复用 viewContext
    // [原理] `viewContext` 被设计为主线程专用，它的并发类型是 `NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType`，
    //        所有操作必须在主线程执行。如果直接在后台线程调用 `viewContext.save()` 会触发 `EXC_BAD_ACCESS` 或数据损坏。
    //        `newBackgroundContext()` 创建的是 `privateQueueConcurrencyType` 上下文，Core Data 会自动管理一个私有队列，
    //        所有操作在这个私有队列中异步执行，通过 `perform(_:)` 或 `performAndWait(_:)` 提交任务。
    // [面试] "Core Data 多线程操作要注意什么？"
    //        答：最核心的原则是"一个线程一个上下文"（NSManagedObjectContext 不是线程安全的）。具体做法：
    //        1) 主线程 UI 操作只用 `viewContext`；2) 后台写入用 `newBackgroundContext()`，通过 `perform` 提交任务；
    //        3) 后台上下文保存后，通过 `automaticallyMergesChangesFromParent` 自动同步到 viewContext；
    //        4) NSManagedObject 不能跨上下文传递，需要用 `objectID` 重新获取。常见的崩溃是 "illegal attempt to establish 
    //        a relationship between objects in different contexts"，就是违反了这条规则。
    /// 创建一个新的后台上下文，用于后台写入操作。
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return context
    }

    /// 保存 viewContext 中未提交的更改。
    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Auto Save

    // MARK: [原理] 自动保存利用 UIApplication 生命周期通知，在 App 进入后台前触发保存
    // [原理] iOS 的 App 生命周期：用户按 Home 键或切换 App 时，系统先发送 `willResignActiveNotification`，
    //        然后发送 `didEnterBackgroundNotification`。在这两个节点保存，可以确保用户离开 App 时的最新状态被持久化。
    //        如果不自动保存，用户可能丢失最近的操作（比如刚完成的学习任务状态）。
    //        这里同时监听两个通知是为了保险：`willResignActive` 是 App 失去焦点但可能还在前台（如接电话），
    //        `didEnterBackground` 是 App 正式进入后台。理论上只监听一个就够了，但双重保障可以避免极端情况遗漏。
    // [面试] "Core Data 的自动保存时机怎么选？"
    //        答：常见时机有三种：1) 用户每次操作后立刻保存（最实时，但频繁写入影响性能，SQLite 的 WAL 模式可缓解）；
    //        2) 界面切换或编辑完成时保存（平衡方案，比如本例的 `willResignActive`）；3) 定时保存（如每 30 秒）。
    //        选择依据是数据重要性和操作频率。本 App 选择"进入后台时保存"，因为：学习任务的完成状态很重要，但操作频率不高，
    //        不需要每次点击都写入磁盘。注意要用 `[weak self]` 避免通知持有 DataController 造成循环引用。
    private func registerAutoSave() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.save()
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.save()
        }
    }

    // MARK: - Preview

    static var preview: DataController = {
        let controller = DataController(inMemory: true)
        CoreDataMigrationHelper.migrateSeedDataIfNeeded(context: controller.viewContext)
        return controller
    }()
}

// MARK: - StringArrayTransformer

/// 将 [String] 数组与 Data 进行双向转换的 Value Transformer。
/// 用于 Core Data 的 Transformable 属性，支持 JSON 编码/解码。
@objc(StringArrayTransformer)
final class StringArrayTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool { true }
    override class func transformedValueClass() -> AnyClass { NSData.self }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let array = value as? [String] else { return nil }
        return try? JSONEncoder().encode(array)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }
}

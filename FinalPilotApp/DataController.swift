import CoreData
import SwiftUI

// MARK: - DataController

/// 管理 Core Data 持久化容器的单例控制器。
/// 提供 viewContext、后台上下文、自动保存和 SwiftUI 预览支持。
final class DataController: ObservableObject {
    static let shared = DataController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
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
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        registerAutoSave()
    }

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

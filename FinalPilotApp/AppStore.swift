import Foundation
import CoreData

final class FinalPilotStore: ObservableObject {
    @Published var courses: [Course]
    @Published var tasks: [StudyTask]
    @Published var careerEvents: [CareerEvent]
    @Published var sprintPlanDays: [SprintPlanDay]
    @Published var flashcards: [KnowledgeFlashcard]
    @Published var attempts: [QuizAttempt]
    
    // MARK: - Core Data Context
    // MARK: [原理] `context` 通过单例懒加载，保持与 DataController 的生命周期绑定
    // [原理] 这里不直接持有 `NSManagedObjectContext`，而是通过 `DataController.shared.viewContext` 间接访问。
    //        好处：1) 如果 DataController 初始化失败，这里返回 nil 而不是崩溃；2) 如果将来需要切换上下文（如支持多用户），
    //        只需修改 DataController 一处，Store 无需改动。`guard let context = context` 的防御性编程在 Core Data 操作中很必要。
    // [面试] "AppStore 里直接操作 Core Data 上下文合适吗？"
    //        答：小规模项目可以，但架构上更推荐用 Repository 模式封装。本 App 采用折中方案：Store 负责业务逻辑和状态管理，
    //        持久化操作通过 `persistTask` / `persistQuizAttempt` 等私有方法封装，外部只调用业务方法（`toggleTask`/`submitAnswer`）。
    //        如果项目继续增长，应将 Core Data 操作抽离为 `TaskRepository`、`QuizRepository` 等，Store 只持有 Repository 协议，
    //        便于单元测试时注入 Mock 对象。这是 Clean Architecture 的依赖倒置原则。
    private var context: NSManagedObjectContext? {
        DataController.shared.viewContext
    }

    init(
        courses: [Course] = SeedData.courses,
        tasks: [StudyTask] = SeedData.tasks,
        careerEvents: [CareerEvent] = SeedData.careerEvents,
        sprintPlanDays: [SprintPlanDay] = SeedData.sprintPlanDays,
        flashcards: [KnowledgeFlashcard] = SeedData.flashcards,
        attempts: [QuizAttempt] = []
    ) {
        self.courses = courses
        self.tasks = tasks
        self.careerEvents = careerEvents
        self.sprintPlanDays = sprintPlanDays
        self.flashcards = flashcards
        self.attempts = attempts
    }

    var nearestExam: Course? {
        courses
            .filter { $0.examDate != nil }
            .sorted { ($0.examDate ?? .distantFuture) < ($1.examDate ?? .distantFuture) }
            .first
    }

    var totalStudyMinutes: Int {
        tasks.filter { $0.status == .done }.reduce(0) { $0 + $1.minutes }
    }

    var completionRate: Double {
        let activeTasks = tasks.filter { $0.bucket != .skip }
        guard !activeTasks.isEmpty else { return 0 }
        let done = activeTasks.filter { $0.status == .done }.count
        return Double(done) / Double(activeTasks.count)
    }

    var highRiskKnowledgePoints: [(Course, KnowledgePoint)] {
        courses.flatMap { course in
            course.knowledgePoints
                .filter { $0.status == .weak || $0.mastery < 0.38 }
                .map { (course, $0) }
        }
        .sorted { lhs, rhs in
            let lhsScore = lhs.1.mastery - Double(lhs.1.difficulty) * 0.04
            let rhsScore = rhs.1.mastery - Double(rhs.1.difficulty) * 0.04
            return lhsScore < rhsScore
        }
    }

    var allQuestions: [QuizQuestion] {
        courses.flatMap(\.questions)
    }

    func tasks(track: TaskTrack, bucket: TaskBucket? = nil) -> [StudyTask] {
        tasks
            .filter { task in
                task.track == track && (bucket == nil || task.bucket == bucket)
            }
            .sorted { lhs, rhs in
                if lhs.bucket != rhs.bucket {
                    return bucketOrder(lhs.bucket) < bucketOrder(rhs.bucket)
                }
                return lhs.minutes > rhs.minutes
            }
    }

    // MARK: toggleTask - 任务状态切换与副作用编排
    // MARK: [原理] 状态机模式：任务状态在 pending ↔ done 之间切换，通过 `wasDone` 记录原状态实现幂等回退
    // [原理] 这里使用内存数组 `tasks` 作为单一事实来源（Single Source of Truth），UI 通过 `@Published` 自动响应。
    //        `firstIndex(where:)` 在 O(n) 时间内定位任务，对于百级数据量完全可接受。如果任务量增长到千级以上，
    //        应考虑将 `tasks` 改为 `Dictionary<String, StudyTask>` 实现 O(1) 查找。
    // [面试] "`@Published` 和 `ObservableObject` 的底层原理是什么？"
    //        答：`@Published` 是一个属性包装器，其 `wrappedValue` 的 `set` 方法会自动调用 `objectWillChange.send()`。
    //        `ObservableObject` 协议有一个默认实现：当对象的 `objectWillChange` Publisher 发出事件时，
    //        SwiftUI 的 `View` 会标记为脏（dirty），在下一个 runloop 重绘。注意：事件在值变化**之前**发出，
    //        所以 View 拿到的是旧值，但 SwiftUI 会重新订阅，下一次 runloop 就能拿到新值。
    //        如果面试追问性能：`@Published` 每次赋值都会发事件，高频场景（如滚动中的坐标）应考虑用 `@State` 或手动节流。
    func toggleTask(_ task: StudyTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let wasDone = tasks[index].status == .done
        tasks[index].status = wasDone ? .pending : .done
        
        // MARK: [原理] 状态切换后立刻持久化，但只写 changed 属性，不是全对象覆盖
        // [原理] Core Data 的 `save()` 只保存被标记为 `hasChanges` 的属性。`NSManagedObject` 内部维护一个"变更集"，
        //        只有被修改的字段会被写入 SQL UPDATE 语句。所以即使每次都调用 `save()`，性能开销也只在实际变更时产生。
        //        这里 `persistTask` 先 fetch 对应 Entity，更新字段后再 save，确保写入最小化。
        // [面试] "Core Data 每次操作都 save 会不会性能很差？"
        //        答：不会。`NSManagedObjectContext.save()` 只做 dirty checking（脏检查），如果 `hasChanges == false` 直接返回。
        //        真正影响性能的是频繁创建/删除 Fetch Request、大量对象遍历。优化策略：1) 批量操作用 `NSBatchUpdateRequest`；
        //        2) 减少 Fetch Request 次数（如本例用 `firstIndex` 在内存数组中定位，而不是每次查数据库）；
        //        3) 使用预取（`fetchRequest.relationshipKeyPathsForPrefetching`）避免 N+1 查询问题。
        // Core Data 持久化
        persistTask(tasks[index])
        
        // MARK: [原理] 即时鼓励通知与业务逻辑分离，通过调度器解耦
        // [原理] 完成 Must 任务后发送通知是"副作用"（side effect），不应直接内嵌在状态切换逻辑中。
        //        这里通过 `StudyReminderScheduler` 单例委托，保持了 Store 的单一职责：只管理数据和状态，不直接操作通知系统。
        //        如果将来需要把通知改为弹窗或积分系统，只需修改调度器，Store 无需改动。
        // 通知反馈
        if !wasDone {
            StudyReminderScheduler.shared.sendTaskCompletionEncouragement(task: task)
        }
        
        // MARK: [原理] Widget 同步与数据持久化必须同时发生，但先后顺序有讲究
        // [原理] Widget 的 Timeline 刷新依赖的是 App Group 共享的 UserDefaults（或 Core Data 共享存储），
        //        所以必须先完成 Core Data 保存，再刷新 Widget。如果先刷新 Widget 再保存 Core Data，Widget 可能读到旧数据。
        //        实际调用 `WidgetCenter.shared.reloadAllTimelines()` 是异步操作，App 不需要等待它完成。
        // Widget 同步
        syncToWidget()
    }

    func deferTask(_ task: StudyTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].status = .deferred
        tasks[index].bucket = .skip
        persistTask(tasks[index])
        syncToWidget()
    }

    // MARK: submitAnswer - 答题提交与掌握度反馈闭环
    // MARK: [原理] 答题流程的完整闭环：归一化比对 → 创建 Attempt → 更新掌握度 → 错题跟进 → 持久化 → 激励通知
    // [原理] 字符串比对前先用 `trimmingCharacters(in: .whitespacesAndNewlines)` 去除首尾空白，
    //        这是因为用户输入或题库数据可能包含不可见字符（如换行、空格），直接 `==` 会导致假阴性（false negative）。
    //        但要注意：这不能解决全角半角问题（如 "A" vs "Ａ"），如果需要更严格的比对，应使用 `precomposedStringWithCanonicalMapping` 做 Unicode 正规化。
    // [面试] "Swift 中比较字符串有哪些坑？怎么解决？"
    //        答：常见坑有：1) 空白字符差异 → 用 `trimmingCharacters`；2) 大小写差异 → 用 `lowercased()` 或 `caseInsensitiveCompare`；
    //        3) Unicode 组合字符差异（如 "é" 可以是单字符 U+00E9，也可以是 e + ́ 两个字符）→ 用 `decomposedStringWithCanonicalMapping`；
    //        4) 本地化排序差异 → 用 `localizedStandardCompare`。本例用的是最基础的 trim + 精确比对，适合封闭式选择题场景。
    @discardableResult
    func submitAnswer(question: QuizQuestion, selectedAnswer: String, confidence: ConfidenceLevel) -> QuizAttempt {
        let normalizedSelected = selectedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAnswer = question.answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let isCorrect = normalizedSelected == normalizedAnswer

        let attempt = QuizAttempt(
            id: UUID().uuidString,
            questionID: question.id,
            knowledgePointID: question.knowledgePointID,
            selectedAnswer: selectedAnswer,
            isCorrect: isCorrect,
            confidence: confidence,
            createdAt: Date()
        )
        attempts.insert(attempt, at: 0)
        
        // MARK: [原理] Confidence Trap 检测：高自信答错比低自信答错危害更大
        // [原理] 认知科学中的"邓宁-克鲁格效应"（Dunning-Kruger Effect）指出：能力不足者往往会高估自己的能力。
        //        本 App 将答题行为分为四个象限：高自信正确、低自信正确、低自信错误、高自信错误。
        //        其中"高自信错误"（Confidence Trap）是最危险的——用户以为自己掌握了但实际没有，考试中会直接丢分。
        //        所以 delta 的惩罚力度设计为：高自信错误 -0.16，低自信错误 -0.1，差距 60%。
        //        奖励侧设计为：高自信正确 +0.08，低自信正确 +0.04，鼓励用户建立准确的自信判断。
        // [面试] "掌握度算法怎么设计的？为什么高自信错误扣更多分？"
        //        答：基于两点心理学研究。1) 间隔重复理论（Spaced Repetition）：学习效果取决于主动回忆和反馈强度；
        //        2) 元认知校准（Metacognitive Calibration）：高自信答错说明用户的"元认知"（对自己知识状态的感知）有偏差，
        //        这种偏差比单纯不会更危险，因为它会导致复习时忽略这个知识点。所以算法设计：
        //        答对 +0.04（低自信）/+0.08（高自信）；答错 -0.1（低自信）/-0.16（高自信）。
        //        另外 `min(1, max(0, mastery + delta))` 保证掌握度在 [0,1] 范围内，避免越界。
        updateMastery(for: question, isCorrect: isCorrect, confidence: confidence)
        
        // MARK: [原理] 错题自动创建后续任务，利用"间隔效应"（Spacing Effect）
        // [原理] 艾宾浩斯遗忘曲线表明：学习后 20 分钟遗忘 42%，1 小时后遗忘 56%，1 天后遗忘 74%。
        //        但如果在遗忘临界点前复习，记忆强度会跃升。本 App 在答错后立即创建一个"24 小时后回顾"的 Must 任务，
        //        在最佳复习窗口期触发回顾，形成"测试-反馈-再学习"的闭环。
        scheduleFollowUpIfNeeded(question: question, isCorrect: isCorrect, confidence: confidence)
        
        // Core Data 持久化
        persistQuizAttempt(attempt)
        
        // 连续答对鼓励
        let recentCorrect = attempts.prefix(3).allSatisfy { $0.isCorrect }
        if recentCorrect {
            StudyReminderScheduler.shared.sendStreakEncouragement(correctCount: 3)
        }
        
        syncToWidget()
        return attempt
    }

    func addMockInterview() {
        let event = CareerEvent(
            id: UUID().uuidString,
            company: "新增公司",
            role: "iOS 开发实习",
            round: "模拟技术面",
            date: .finalPilotDate(month: 5, day: 10, hour: 15),
            importance: 3,
            preparationStatus: "等待准备"
        )
        careerEvents.append(event)
        syncToWidget()
    }

    // MARK: daysUntil - 跨时区考试倒计时计算
    // MARK: [原理] 日期计算的核心是"日期语义"与"物理时间"的分离。`Date` 是物理时间（UTC 时间戳），
    //        而人类理解的"还有几天考试"是语义时间（取决于时区和日历规则）。
    //        本方法的关键设计：1) 显式指定考试所在时区（Europe/London），避免用户跨时区旅行导致倒计时错乱；
    //        2) 使用 `startOfDay(for:)` 将两个时间点都归一化为当天的 00:00:00，消除时分秒差异；
    //        3) 用 `dateComponents([.day], from:to:)` 计算天数差，而不是自己除 86400，因为夏令时切换当天不是 86400 秒。
    // [面试] "如果用户从伦敦飞到纽约，倒计时应该怎么处理？"
    //        答：取决于产品需求。如果考试在伦敦举行，倒计时应该基于伦敦时间（如本例），因为考试开始时间是伦敦当地的 9:00 AM，
    //        不是用户所在地的 9:00 AM。如果基于设备本地时区，用户到纽约后，考试倒计时可能多算或少算一天。
    //        另一种场景是在线考试（不限地点），则可以基于 UTC 计算，所有用户看到相同的倒计时。
    //        最严谨的做法：将考试日期存储为 `DateComponents`（年月日时区）而非 `Date`，这样时区信息不会丢失。
    func daysUntil(_ date: Date?, from now: Date = Date()) -> Int? {
        guard let date else { return nil }
        
        // MARK: [原理] Calendar 的时区处理：为什么显式设置 Europe/London
        // [原理] `Date` 在 Swift 中是 UTC 时间戳，不带时区信息。`Calendar` 负责将时间戳映射到人类理解的"年月日时分秒"。
        //        如果不显式设置 `timeZone`，`Calendar.current` 会使用设备当前时区。但本 App 的用户可能在考试期间旅行，
        //        如果在伦敦考试期间到了纽约，设备的本地时区变了，倒计时就会算错（因为日期分界点变了）。
        //        显式设置为考试所在时区（Europe/London）确保无论用户在哪里，倒计时都基于伦敦时间计算。
        //        `startOfDay(for:)` 是关键 API：它将任意时间点归一化为当天的 00:00:00，消除时分秒差异，只比较日期差。
        // [面试] "Swift 中如何正确计算两个日期之间的天数差？有什么坑？"
        //        答：最坑的是直接用 `timeIntervalSince` 除以 86400，因为：1) 夏令时（DST）切换当天不是 86400 秒；
        //        2) 没有考虑时区；3) 没有考虑闰秒。正确做法：用 `Calendar.dateComponents([.day], from: startOfDay1, to: startOfDay2)`。
        //        步骤：1) 创建 Calendar 并设置正确的 timeZone；2) 用 `startOfDay(for:)` 将两个 Date 归零为当天 00:00；
        //        3) 取 `.day` 组件。本例还加了 `guard date > now` 的防护，防止过期日期返回负数。
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    // MARK: - Widget Sync
    
    // MARK: syncToWidget - App Group 共享数据与 Widget 刷新
    // MARK: [原理] Widget Extension 是独立进程，与主 App 不共享内存，必须通过 App Group 的共享容器交换数据。
    //        本方法将三类数据序列化为轻量结构写入 `UserDefaults(suiteName:)`：1) 考试倒计时（WidgetExamInfo）；
    //        2) 待办任务列表（WidgetTaskInfo）；3) 学习进度统计（WidgetProgressInfo）。
    //        选择 UserDefaults 而非 Core Data 共享容器的原因是：Widget 数据量小、结构简单、更新频繁，
    //        UserDefaults 的键值读写性能更优，且避免了 Core Data 并发上下文的复杂性。
    // [面试] "Widget 怎么和主 App 共享数据？刷新有什么限制？"
    //        答：核心机制是 App Group。步骤：1) 在 Xcode 的 Capabilities 中为主 App 和 Widget Extension 启用 App Group，
    //        选择同一个 group identifier（如 `group.com.finalpilot`）；2) 使用 `UserDefaults(suiteName: "group.com.finalpilot")` 读写；
    //        3) 或者用 `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` 获取共享目录，存 SQLite 或 JSON 文件。
    //        注意：App Group 的 UserDefaults 和 `UserDefaults.standard` 是隔离的，Widget 不能读 `standard` 里的数据。
    //        刷新限制：iOS 对 Widget 的 Timeline 刷新有配额限制（通常每天几十次），频繁调用 `reloadAllTimelines()` 会被系统节流。
    //        优化策略：1) 使用 `reloadTimelines(ofKind:)` 只刷新特定 Widget；2) 合理设置 `TimelineReloadPolicy`（如 `.after(date)`）；
    //        3) 在 App 进入后台或数据显著变化时再刷新，而非每次小变更都刷新。
    func syncToWidget() {
        // 同步考试信息
        let examInfos = courses.compactMap { course -> WidgetExamInfo? in
            guard let days = daysUntil(course.examDate) else { return nil }
            return WidgetExamInfo(
                id: course.id,
                name: course.name.prefixName,
                daysUntil: days,
                examDate: course.examDate ?? Date()
            )
        }
        WidgetDataProvider.shared.saveExams(examInfos)
        
        // 同步任务
        let taskInfos = tasks.filter { $0.bucket == .must && $0.status != .done }.map { task -> WidgetTaskInfo in
            WidgetTaskInfo(
                id: task.id,
                title: task.title,
                subtitle: task.subtitle,
                minutes: task.minutes,
                isCompleted: task.status == .done
            )
        }
        WidgetDataProvider.shared.saveTasks(taskInfos)
        
        // 同步进度
        let progress = WidgetProgressInfo(
            completionRate: completionRate,
            studyMinutes: totalStudyMinutes,
            totalTasks: tasks.filter { $0.bucket != .skip }.count,
            completedTasks: tasks.filter { $0.status == .done }.count
        )
        WidgetDataProvider.shared.saveProgress(progress)
    }

    // MARK: - Core Data Persistence
    
    // MARK: persistTask - Core Data 任务持久化（Upsert 模式）
    // MARK: [原理] Upsert（Update or Insert）模式：先 Fetch 已有记录，存在则更新，不存在则新建。
    //        这种模式避免了重复插入导致的主键冲突，同时保证数据一致性。`NSFetchRequest` 通过 `predicate` 限定查询范围，
    //        这里用 `id == %@` 精确匹配，利用 SQLite 的索引实现 O(log n) 查找。`Int32` 是 Core Data 对 Swift `Int` 的映射类型，
    //        因为 Objective-C 的 `NSInteger` 在 32 位/64 位平台宽度不同，Core Data 选择 `Int32` 保证跨平台一致性。
    // [面试] "Core Data 的 `save()` 是线程安全的吗？"
    //        答：**不是**。`NSManagedObjectContext` 不是线程安全的，所有操作必须在创建它的线程（或队列）上执行。
    //        `viewContext` 是主队列上下文，所以本方法必须在主线程调用。如果在后台线程操作 Core Data，需要：
    //        1) 创建 `NSPersistentContainer.newBackgroundContext()`；2) 在该 context 的 `perform` 或 `performAndWait` 块中执行；
    //        3) 通过 `mergePolicy` 处理冲突（如 `NSMergeByPropertyObjectTrumpMergePolicy`）。
    //        常见面试陷阱：`DispatchQueue.global().async { context.save() }` 会崩溃或产生未定义行为。
    private func persistTask(_ task: StudyTask) {
        guard let context = context else { return }
        let fetchRequest: NSFetchRequest<StudyTaskEntity> = StudyTaskEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", task.id)
        
        do {
            let results = try context.fetch(fetchRequest)
            let entity = results.first ?? StudyTaskEntity(context: context)
            entity.id = task.id
            entity.track = task.track.rawValue
            entity.bucket = task.bucket.rawValue
            entity.title = task.title
            entity.subtitle = task.subtitle
            entity.minutes = Int32(task.minutes)
            entity.reason = task.reason
            entity.linkedCourseID = task.linkedCourseID
            entity.status = task.status.rawValue
            try context.save()
        } catch {
            print("Persist task error: \(error)")
        }
    }
    
    // MARK: persistQuizAttempt - 答题记录持久化（纯 Insert 模式）
    // MARK: [原理] 与 `persistTask` 的 Upsert 不同，QuizAttempt 是追加-only 的审计日志，每次答题都生成新记录，永不更新旧记录。
    //        这种设计符合事件溯源（Event Sourcing）思想：系统状态不是存储在某个字段中，而是由一系列不可变事件推导得出。
    //        好处：1) 完整保留学习轨迹，可用于后续分析（如"本周在哪些知识点上犯了高自信错误"）；
    //        2) 防止数据篡改，历史记录不可变；3) 便于实现"撤销"功能（只需忽略某条记录重新计算）。
    // [面试] "为什么选择追加-only 而不是更新 mastery 字段？"
    //        答：这是"派生状态"与"原始事件"的架构抉择。如果直接覆盖 mastery，历史就丢失了，无法做学习分析。
    //        追加-only 的代价是数据量大后查询变慢，优化方案：1) 定期将旧事件归档到压缩文件；2) 维护一个物化视图（Materialized View）
    //        缓存当前的 mastery 值，事件只追加到日志，查询时读缓存；3) 使用 Core Data 的批量删除清理过期数据。
    //        在金融系统中，这种设计叫 Event Sourcing + CQRS（命令查询职责分离），是微服务架构的常用模式。
    private func persistQuizAttempt(_ attempt: QuizAttempt) {
        guard let context = context else { return }
        let entity = QuizAttemptEntity(context: context)
        entity.id = attempt.id
        entity.questionID = attempt.questionID
        entity.knowledgePointID = attempt.knowledgePointID
        entity.selectedAnswer = attempt.selectedAnswer
        entity.isCorrect = attempt.isCorrect
        entity.confidence = attempt.confidence.rawValue
        entity.createdAt = attempt.createdAt
        
        do {
            try context.save()
        } catch {
            print("Persist attempt error: \(error)")
        }
    }

    // MARK: updateMastery - 掌握度 Delta 算法（四象限反馈模型）
    // MARK: [原理] 信号检测理论（Signal Detection Theory）将决策分为四种：Hit（高自信正确）、Miss（低自信错误）、
    //        False Alarm（高自信错误）、Correct Rejection（低自信正确）。本算法将 False Alarm 的惩罚（-0.16）设为 Miss（-0.10）的 1.6 倍，
    //        因为 False Alarm 代表"认知偏差"——用户不仅错了，还不知道自己错了，这种偏差会导致后续复习中主动忽略该知识点。
    //        0.08 和 0.04 的奖励差两倍，是鼓励用户培养自信判断能力，而非盲目猜测。
    //        阈值 0.72（mastered）和 0.38（weak）是经验值，参考了 SuperMemo 的 SM-2 算法中 "easy threshold" 和 "forgetting threshold"。
    // [面试] "这个掌握度算法如果面试被问到，怎么讲清楚？"
    //        答：可以从三个维度讲。1) 理论基础：基于艾宾浩斯遗忘曲线和间隔重复，通过测试驱动回忆来强化记忆；
    //        2) 算法设计：四象限反馈（高/低自信 × 正确/错误），高自信错误的惩罚最重，因为它代表元认知偏差；
    //        3) 工程实现：用 `min(1, max(0, ...))` 做边界保护，状态机（mastered/inProgress/weak）让 UI 可以直观展示学习进度。
    //        如果面试官追问改进空间：可以引入时间衰减因子（最近答错权重更大）、可以加入知识点关联度（一个知识点掌握会带动相关知识点）、
    //        可以替换为更成熟的 SM-2 或 FSRS 算法（Free Spaced Repetition Scheduler）。
    private func updateMastery(for question: QuizQuestion, isCorrect: Bool, confidence: ConfidenceLevel) {
        guard
            let courseIndex = courses.firstIndex(where: { $0.id == question.courseID }),
            let pointIndex = courses[courseIndex].knowledgePoints.firstIndex(where: { $0.id == question.knowledgePointID })
        else { return }

        var point = courses[courseIndex].knowledgePoints[pointIndex]
        
        // MARK: [原理] 掌握度 delta 的量化心理学基础：信号检测理论（Signal Detection Theory）
        // [原理] 信号检测理论将决策分为四种：Hit（高自信正确）、Miss（低自信错误）、False Alarm（高自信错误）、Correct Rejection（低自信正确）。
        //        本算法将 False Alarm 的惩罚（-0.16）设为 Miss（-0.10）的 1.6 倍，因为 False Alarm 代表"认知偏差"——
        //        用户不仅错了，还不知道自己错了，这种偏差会导致后续复习中主动忽略该知识点。
        //        0.08 和 0.04 的奖励差两倍，是鼓励用户培养自信判断能力，而非盲目猜测。
        //        阈值 0.72（mastered）和 0.38（weak）是经验值，参考了 SuperMemo 的 SM-2 算法中 "easy threshold" 和 "forgetting threshold" 的设定。
        // [面试] "这个掌握度算法如果面试被问到，怎么讲清楚？"
        //        答：可以从三个维度讲。1) 理论基础：基于艾宾浩斯遗忘曲线和间隔重复，通过测试驱动回忆来强化记忆；
        //        2) 算法设计：四象限反馈（高/低自信 × 正确/错误），高自信错误的惩罚最重，因为它代表元认知偏差；
        //        3) 工程实现：用 `min(1, max(0, ...))` 做边界保护，状态机（mastered/inProgress/weak）让 UI 可以直观展示学习进度。
        //        如果面试官追问改进空间：可以引入时间衰减因子（最近答错权重更大）、可以加入知识点关联度（一个知识点掌握会带动相关知识点）、
        //        可以替换为更成熟的 SM-2 或 FSRS 算法（Free Spaced Repetition Scheduler）。
        let delta: Double
        if isCorrect {
            delta = confidence == .high ? 0.08 : 0.04
        } else {
            delta = confidence == .high ? -0.16 : -0.1
        }
        point.mastery = min(1, max(0, point.mastery + delta))
        if point.mastery >= 0.72 {
            point.status = .mastered
        } else if point.mastery < 0.38 {
            point.status = .weak
        } else {
            point.status = .inProgress
        }
        courses[courseIndex].knowledgePoints[pointIndex] = point
        
        // 持久化知识点掌握度
        persistKnowledgePoint(point, courseID: question.courseID)
    }
    
    // MARK: persistKnowledgePoint - 知识点掌握度持久化（精准更新）
    // MARK: [原理] 精准更新模式：只 Fetch 目标记录，更新 `mastery` 和 `status` 两个字段，不触碰其他属性。
    //        Core Data 的脏检查机制会自动追踪变更属性，`save()` 时只生成包含变更字段的 UPDATE SQL，而非整行覆盖。
    //        这比"读出整行 → 修改 → 写回整行"更高效，尤其在并发场景下减少了写冲突的概率。
    // [面试] "Core Data 和 SQLite 直接操作有什么区别？各有什么优劣？"
    //        答：Core Data 是对象图管理框架，不是简单的 ORM。优势：1) 对象生命周期管理（ faulting / uniquing 节省内存）；
    //        2) 变更追踪和懒保存；3) 支持撤销（Undo）；4) 与 Xcode 可视化编辑器集成。劣势：1) 学习曲线陡峭；
    //        2) 多线程复杂（context 绑定队列）；3) 大数据量性能不如直接 SQL（如批量更新用 `NSBatchUpdateRequest` 绕过对象图）；
    //        4) 跨平台支持差（仅限 Apple 生态）。如果项目需要 Android 端共享数据库，应考虑 SQLite 或 Realm。
    private func persistKnowledgePoint(_ point: KnowledgePoint, courseID: String) {
        guard let context = context else { return }
        let fetchRequest: NSFetchRequest<KnowledgePointEntity> = KnowledgePointEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", point.id)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let entity = results.first {
                entity.mastery = point.mastery
                entity.status = point.status.rawValue
                try context.save()
            }
        } catch {
            print("Persist knowledge point error: \(error)")
        }
    }

    // MARK: scheduleFollowUpIfNeeded - 错题跟进任务的智能调度（间隔效应）
    // MARK: [原理] 艾宾浩斯遗忘曲线表明：学习后 20 分钟遗忘 42%，1 小时后遗忘 56%，1 天后遗忘 74%。
    //        但如果在遗忘临界点前复习，记忆强度会跃升。本方法在答错后立即创建一个"24 小时后回顾"的 Must 任务，
    //        在最佳复习窗口期触发回顾，形成"测试-反馈-再学习"的闭环。`alreadyExists` 检查防止同一知识点重复创建跟进任务。
    // [面试] "怎么实现一个更通用的间隔重复调度系统？"
    //        答：可以借鉴 SM-2 算法：每个知识点维护一个 `interval`（间隔天数）、`repetitions`（连续正确次数）、`efactor`（简易度因子）。
    //        公式：interval(1)=1, interval(2)=6, interval(n)=interval(n-1)*efactor。答对时 efactor 增加，答错时重置。
    //        更先进的 FSRS 算法（Free Spaced Repetition Scheduler）用三个维度（难度、稳定性、可检索性）建模记忆状态，
    //        通过机器学习优化参数，被 Anki、RemNote 等应用采用。实现时可以用 `UNNotificationTrigger` 的 `timeInterval` 或 `dateMatching` 触发提醒。
    private func scheduleFollowUpIfNeeded(question: QuizQuestion, isCorrect: Bool, confidence: ConfidenceLevel) {
        guard !isCorrect else { return }
        let alreadyExists = tasks.contains { $0.id == "followup_\(question.knowledgePointID)" }
        guard !alreadyExists else { return }

        let title = confidence == .high ? "危险误区复盘" : "错题变体练习"
        let task = StudyTask(
            id: "followup_\(question.knowledgePointID)",
            track: .exam,
            bucket: .must,
            title: title,
            subtitle: "\(question.sourceType.label) · \(question.sourceTitle)",
            minutes: confidence == .high ? 20 : 15,
            reason: confidence == .high ? "高自信错误比普通错误更危险。回到 \(question.sourceDetail) 做一次变体。" : "错题需要在 24 小时内回看。来源：\(question.sourceDetail)",
            linkedCourseID: question.courseID,
            status: .pending
        )
        tasks.insert(task, at: 0)
        persistTask(task)
        
        // 错题回顾通知
        StudyReminderScheduler.shared.scheduleMistakeReviewReminders(store: self)
    }

    private func bucketOrder(_ bucket: TaskBucket) -> Int {
        switch bucket {
        case .must: 0
        case .should: 1
        case .skip: 2
        }
    }
}

import CoreData
import Foundation

// MARK: - 使用说明
// 本文件定义了所有 Core Data 实体的 NSManagedObject 子类。
// 在 Xcode 中打开 FinalPilot.xcdatamodeld，选择所有实体，
// 在 Data Model Inspector 中将 Codegen 设为 "Manual/None"，
// 以避免 Xcode 自动生成重复类定义。

// MARK: - CourseEntity

@objc(CourseEntity)
public class CourseEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var examDate: Date?
    @NSManaged public var examDurationMinutes: NSNumber?
    @NSManaged public var examLocation: String?
    @NSManaged public var difficulty: Int32
    @NSManaged public var colorKey: String
    @NSManaged public var symbol: String
    @NSManaged public var knowledgePoints: NSSet?
    @NSManaged public var questions: NSSet?
}

extension CourseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CourseEntity> {
        return NSFetchRequest<CourseEntity>(entityName: "CourseEntity")
    }

    // MARK: 关系访问器

    @objc(addKnowledgePointsObject:)
    @NSManaged public func addToKnowledgePoints(_ value: KnowledgePointEntity)

    @objc(removeKnowledgePointsObject:)
    @NSManaged public func removeFromKnowledgePoints(_ value: KnowledgePointEntity)

    @objc(addKnowledgePoints:)
    @NSManaged public func addToKnowledgePoints(_ values: NSSet)

    @objc(removeKnowledgePoints:)
    @NSManaged public func removeFromKnowledgePoints(_ values: NSSet)

    @objc(addQuestionsObject:)
    @NSManaged public func addToQuestions(_ value: QuizQuestionEntity)

    @objc(removeQuestionsObject:)
    @NSManaged public func removeFromQuestions(_ value: QuizQuestionEntity)

    @objc(addQuestions:)
    @NSManaged public func addToQuestions(_ values: NSSet)

    @objc(removeQuestions:)
    @NSManaged public func removeFromQuestions(_ values: NSSet)

    // MARK: 计算属性

    var knowledgePointsArray: [KnowledgePointEntity] {
        let set = knowledgePoints as? Set<KnowledgePointEntity> ?? []
        return Array(set).sorted { $0.title < $1.title }
    }

    var questionsArray: [QuizQuestionEntity] {
        let set = questions as? Set<QuizQuestionEntity> ?? []
        return Array(set)
    }

    var masteryAverage: Double {
        let points = knowledgePointsArray
        guard !points.isEmpty else { return 0 }
        let total = points.reduce(0) { $0 + $1.mastery }
        return total / Double(points.count)
    }

    var weakPoints: [KnowledgePointEntity] {
        knowledgePointsArray.filter { $0.status == KnowledgeStatus.weak.rawValue || $0.mastery < 0.38 }
    }

    var examDurationMinutesValue: Int? {
        examDurationMinutes?.intValue
    }

    // MARK: 转换方法

    static func fromCourse(_ course: Course, context: NSManagedObjectContext) -> CourseEntity {
        let entity = CourseEntity(context: context)
        entity.id = course.id
        entity.name = course.name
        entity.examDate = course.examDate
        if let minutes = course.examDurationMinutes {
            entity.examDurationMinutes = NSNumber(value: minutes)
        }
        entity.examLocation = course.examLocation
        entity.difficulty = Int32(course.difficulty)
        entity.colorKey = course.colorKey
        entity.symbol = course.symbol

        for point in course.knowledgePoints {
            let pointEntity = KnowledgePointEntity.fromKnowledgePoint(point, context: context)
            entity.addToKnowledgePoints(pointEntity)
        }

        for question in course.questions {
            let questionEntity = QuizQuestionEntity.fromQuizQuestion(question, context: context)
            entity.addToQuestions(questionEntity)
        }

        return entity
    }

    func toCourse() -> Course {
        Course(
            id: id,
            name: name,
            examDate: examDate,
            examDurationMinutes: examDurationMinutes?.intValue,
            examLocation: examLocation,
            difficulty: Int(difficulty),
            colorKey: colorKey,
            symbol: symbol,
            knowledgePoints: knowledgePointsArray.map { $0.toKnowledgePoint() },
            questions: questionsArray.map { $0.toQuizQuestion() }
        )
    }
}

// MARK: - KnowledgePointEntity

@objc(KnowledgePointEntity)
public class KnowledgePointEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var chapter: String
    @NSManaged public var title: String
    @NSManaged public var difficulty: Int32
    @NSManaged public var mastery: Double
    @NSManaged public var status: String
    @NSManaged public var course: CourseEntity?
}

extension KnowledgePointEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<KnowledgePointEntity> {
        return NSFetchRequest<KnowledgePointEntity>(entityName: "KnowledgePointEntity")
    }

    static func fromKnowledgePoint(_ point: KnowledgePoint, context: NSManagedObjectContext) -> KnowledgePointEntity {
        let entity = KnowledgePointEntity(context: context)
        entity.id = point.id
        entity.chapter = point.chapter
        entity.title = point.title
        entity.difficulty = Int32(point.difficulty)
        entity.mastery = point.mastery
        entity.status = point.status.rawValue
        return entity
    }

    func toKnowledgePoint() -> KnowledgePoint {
        KnowledgePoint(
            id: id,
            chapter: chapter,
            title: title,
            difficulty: Int(difficulty),
            mastery: mastery,
            status: KnowledgeStatus(rawValue: status) ?? .notStarted
        )
    }
}

// MARK: - QuizQuestionEntity

@objc(QuizQuestionEntity)
public class QuizQuestionEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var courseID: String
    @NSManaged public var knowledgePointID: String
    @NSManaged public var type: String
    @NSManaged public var difficulty: String
    @NSManaged public var question: String
    @NSManaged public var options: [String]?
    @NSManaged public var answer: String
    @NSManaged public var explanation: String
    @NSManaged public var sourceType: String
    @NSManaged public var sourceTitle: String
    @NSManaged public var sourceDetail: String
    @NSManaged public var examValue: Int32
    @NSManaged public var examPrompt: String
    @NSManaged public var course: CourseEntity?
}

extension QuizQuestionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuizQuestionEntity> {
        return NSFetchRequest<QuizQuestionEntity>(entityName: "QuizQuestionEntity")
    }

    var sourceTypeEnum: QuestionSourceType {
        QuestionSourceType(rawValue: sourceType) ?? .lecture
    }

    static func fromQuizQuestion(_ question: QuizQuestion, context: NSManagedObjectContext) -> QuizQuestionEntity {
        let entity = QuizQuestionEntity(context: context)
        entity.id = question.id
        entity.courseID = question.courseID
        entity.knowledgePointID = question.knowledgePointID
        entity.type = question.type
        entity.difficulty = question.difficulty
        entity.question = question.question
        entity.options = question.options
        entity.answer = question.answer
        entity.explanation = question.explanation
        entity.sourceType = question.sourceType.rawValue
        entity.sourceTitle = question.sourceTitle
        entity.sourceDetail = question.sourceDetail
        entity.examValue = Int32(question.examValue)
        entity.examPrompt = question.examPrompt
        return entity
    }

    func toQuizQuestion() -> QuizQuestion {
        QuizQuestion(
            id: id,
            courseID: courseID,
            knowledgePointID: knowledgePointID,
            type: type,
            difficulty: difficulty,
            question: question,
            options: options ?? [],
            answer: answer,
            explanation: explanation,
            sourceType: QuestionSourceType(rawValue: sourceType) ?? .lecture,
            sourceTitle: sourceTitle,
            sourceDetail: sourceDetail,
            examValue: Int(examValue),
            examPrompt: examPrompt
        )
    }
}

// MARK: - StudyTaskEntity

@objc(StudyTaskEntity)
public class StudyTaskEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var track: String
    @NSManaged public var bucket: String
    @NSManaged public var title: String
    @NSManaged public var subtitle: String
    @NSManaged public var minutes: Int32
    @NSManaged public var reason: String
    @NSManaged public var linkedCourseID: String?
    @NSManaged public var status: String
}

extension StudyTaskEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StudyTaskEntity> {
        return NSFetchRequest<StudyTaskEntity>(entityName: "StudyTaskEntity")
    }

    var trackEnum: TaskTrack {
        TaskTrack(rawValue: track) ?? .exam
    }

    var bucketEnum: TaskBucket {
        TaskBucket(rawValue: bucket) ?? .must
    }

    var statusEnum: TaskStatus {
        TaskStatus(rawValue: status) ?? .pending
    }

    static func fromStudyTask(_ task: StudyTask, context: NSManagedObjectContext) -> StudyTaskEntity {
        let entity = StudyTaskEntity(context: context)
        entity.id = task.id
        entity.track = task.track.rawValue
        entity.bucket = task.bucket.rawValue
        entity.title = task.title
        entity.subtitle = task.subtitle
        entity.minutes = Int32(task.minutes)
        entity.reason = task.reason
        entity.linkedCourseID = task.linkedCourseID
        entity.status = task.status.rawValue
        return entity
    }

    func toStudyTask() -> StudyTask {
        StudyTask(
            id: id,
            track: TaskTrack(rawValue: track) ?? .exam,
            bucket: TaskBucket(rawValue: bucket) ?? .must,
            title: title,
            subtitle: subtitle,
            minutes: Int(minutes),
            reason: reason,
            linkedCourseID: linkedCourseID,
            status: TaskStatus(rawValue: status) ?? .pending
        )
    }
}

// MARK: - CareerEventEntity

@objc(CareerEventEntity)
public class CareerEventEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var company: String
    @NSManaged public var role: String
    @NSManaged public var round: String
    @NSManaged public var date: Date
    @NSManaged public var importance: Int32
    @NSManaged public var preparationStatus: String
}

extension CareerEventEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CareerEventEntity> {
        return NSFetchRequest<CareerEventEntity>(entityName: "CareerEventEntity")
    }

    static func fromCareerEvent(_ event: CareerEvent, context: NSManagedObjectContext) -> CareerEventEntity {
        let entity = CareerEventEntity(context: context)
        entity.id = event.id
        entity.company = event.company
        entity.role = event.role
        entity.round = event.round
        entity.date = event.date
        entity.importance = Int32(event.importance)
        entity.preparationStatus = event.preparationStatus
        return entity
    }

    func toCareerEvent() -> CareerEvent {
        CareerEvent(
            id: id,
            company: company,
            role: role,
            round: round,
            date: date,
            importance: Int(importance),
            preparationStatus: preparationStatus
        )
    }
}

// MARK: - SprintPlanDayEntity

@objc(SprintPlanDayEntity)
public class SprintPlanDayEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var dateLabel: String
    @NSManaged public var weekday: String
    @NSManaged public var phase: String
    @NSManaged public var marker: String?
    @NSManaged public var c310Task: String
    @NSManaged public var e320Task: String
    @NSManaged public var output: String
    @NSManaged public var checklist: [String]?
}

extension SprintPlanDayEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SprintPlanDayEntity> {
        return NSFetchRequest<SprintPlanDayEntity>(entityName: "SprintPlanDayEntity")
    }

    var phaseEnum: SprintPlanPhase {
        SprintPlanPhase(rawValue: phase) ?? .foundation
    }

    var isExamDay: Bool {
        marker?.contains("考试") == true
    }

    static func fromSprintPlanDay(_ day: SprintPlanDay, context: NSManagedObjectContext) -> SprintPlanDayEntity {
        let entity = SprintPlanDayEntity(context: context)
        entity.id = day.id
        entity.dateLabel = day.dateLabel
        entity.weekday = day.weekday
        entity.phase = day.phase.rawValue
        entity.marker = day.marker
        entity.c310Task = day.c310Task
        entity.e320Task = day.e320Task
        entity.output = day.output
        entity.checklist = day.checklist
        return entity
    }

    func toSprintPlanDay() -> SprintPlanDay {
        SprintPlanDay(
            id: id,
            dateLabel: dateLabel,
            weekday: weekday,
            phase: SprintPlanPhase(rawValue: phase) ?? .foundation,
            marker: marker,
            c310Task: c310Task,
            e320Task: e320Task,
            output: output,
            checklist: checklist ?? []
        )
    }
}

// MARK: - KnowledgeFlashcardEntity

@objc(KnowledgeFlashcardEntity)
public class KnowledgeFlashcardEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var courseID: String
    @NSManaged public var knowledgePointID: String
    @NSManaged public var dayLabel: String
    @NSManaged public var title: String
    @NSManaged public var prompt: String
    @NSManaged public var answer: String
    @NSManaged public var examHint: String
    @NSManaged public var sourceTitle: String
    @NSManaged public var tags: [String]?
    @NSManaged public var priority: Int32
}

extension KnowledgeFlashcardEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<KnowledgeFlashcardEntity> {
        return NSFetchRequest<KnowledgeFlashcardEntity>(entityName: "KnowledgeFlashcardEntity")
    }

    static func fromKnowledgeFlashcard(_ card: KnowledgeFlashcard, context: NSManagedObjectContext) -> KnowledgeFlashcardEntity {
        let entity = KnowledgeFlashcardEntity(context: context)
        entity.id = card.id
        entity.courseID = card.courseID
        entity.knowledgePointID = card.knowledgePointID
        entity.dayLabel = card.dayLabel
        entity.title = card.title
        entity.prompt = card.prompt
        entity.answer = card.answer
        entity.examHint = card.examHint
        entity.sourceTitle = card.sourceTitle
        entity.tags = card.tags
        entity.priority = Int32(card.priority)
        return entity
    }

    func toKnowledgeFlashcard() -> KnowledgeFlashcard {
        KnowledgeFlashcard(
            id: id,
            courseID: courseID,
            knowledgePointID: knowledgePointID,
            dayLabel: dayLabel,
            title: title,
            prompt: prompt,
            answer: answer,
            examHint: examHint,
            sourceTitle: sourceTitle,
            tags: tags ?? [],
            priority: Int(priority)
        )
    }
}

// MARK: - QuizAttemptEntity

@objc(QuizAttemptEntity)
public class QuizAttemptEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var questionID: String
    @NSManaged public var knowledgePointID: String
    @NSManaged public var selectedAnswer: String
    @NSManaged public var isCorrect: Bool
    @NSManaged public var confidence: String
    @NSManaged public var createdAt: Date
}

extension QuizAttemptEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuizAttemptEntity> {
        return NSFetchRequest<QuizAttemptEntity>(entityName: "QuizAttemptEntity")
    }

    var confidenceEnum: ConfidenceLevel {
        ConfidenceLevel(rawValue: confidence) ?? .medium
    }

    static func fromQuizAttempt(_ attempt: QuizAttempt, context: NSManagedObjectContext) -> QuizAttemptEntity {
        let entity = QuizAttemptEntity(context: context)
        entity.id = attempt.id
        entity.questionID = attempt.questionID
        entity.knowledgePointID = attempt.knowledgePointID
        entity.selectedAnswer = attempt.selectedAnswer
        entity.isCorrect = attempt.isCorrect
        entity.confidence = attempt.confidence.rawValue
        entity.createdAt = attempt.createdAt
        return entity
    }

    func toQuizAttempt() -> QuizAttempt {
        QuizAttempt(
            id: id,
            questionID: questionID,
            knowledgePointID: knowledgePointID,
            selectedAnswer: selectedAnswer,
            isCorrect: isCorrect,
            confidence: ConfidenceLevel(rawValue: confidence) ?? .medium,
            createdAt: createdAt
        )
    }
}

// MARK: - DailyStudyRecordEntity

@objc(DailyStudyRecordEntity)
public class DailyStudyRecordEntity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var date: Date
    @NSManaged public var totalMinutes: Int32
    @NSManaged public var completedTasks: Int32
    @NSManaged public var correctAnswers: Int32
    @NSManaged public var totalAnswers: Int32
    @NSManaged public var notes: String?
}

extension DailyStudyRecordEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyStudyRecordEntity> {
        return NSFetchRequest<DailyStudyRecordEntity>(entityName: "DailyStudyRecordEntity")
    }

    static func createDailyRecord(
        date: Date,
        totalMinutes: Int,
        completedTasks: Int,
        correctAnswers: Int,
        totalAnswers: Int,
        notes: String? = nil,
        context: NSManagedObjectContext
    ) -> DailyStudyRecordEntity {
        let entity = DailyStudyRecordEntity(context: context)
        entity.id = UUID().uuidString
        entity.date = date
        entity.totalMinutes = Int32(totalMinutes)
        entity.completedTasks = Int32(completedTasks)
        entity.correctAnswers = Int32(correctAnswers)
        entity.totalAnswers = Int32(totalAnswers)
        entity.notes = notes
        return entity
    }

    var accuracyRate: Double {
        guard totalAnswers > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalAnswers)
    }
}

// MARK: - 便捷查询扩展

extension NSManagedObjectContext {
    /// 获取所有课程实体，按考试日期排序。
    func fetchAllCourses() -> [CourseEntity] {
        let request = CourseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "examDate", ascending: true)]
        return (try? fetch(request)) ?? []
    }

    /// 获取所有活跃（非 Skip）任务。
    func fetchActiveTasks() -> [StudyTaskEntity] {
        let request = StudyTaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "bucket != %@", TaskBucket.skip.rawValue)
        return (try? fetch(request)) ?? []
    }

    /// 获取今日学习记录（按日期）。
    func fetchDailyRecord(for date: Date) -> DailyStudyRecordEntity? {
        let request = DailyStudyRecordEntity.fetchRequest()
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", start as NSDate, end as NSDate)
        request.fetchLimit = 1
        return (try? fetch(request))?.first
    }

    /// 删除指定 ID 的实体。
    func deleteEntity<T: NSManagedObject>(byID id: String, request: NSFetchRequest<T>) {
        request.predicate = NSPredicate(format: "id == %@", id)
        if let entity = (try? fetch(request))?.first {
            delete(entity)
        }
    }
}

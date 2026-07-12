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

    func toggleTask(_ task: StudyTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let wasDone = tasks[index].status == .done
        tasks[index].status = wasDone ? .pending : .done
        
        // Core Data 持久化
        persistTask(tasks[index])
        
        // 通知反馈
        if !wasDone {
            StudyReminderScheduler.shared.sendTaskCompletionEncouragement(task: task)
        }
        
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
        updateMastery(for: question, isCorrect: isCorrect, confidence: confidence)
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

    func daysUntil(_ date: Date?, from now: Date = Date()) -> Int? {
        guard let date else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    // MARK: - Widget Sync
    
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

    private func updateMastery(for question: QuizQuestion, isCorrect: Bool, confidence: ConfidenceLevel) {
        guard
            let courseIndex = courses.firstIndex(where: { $0.id == question.courseID }),
            let pointIndex = courses[courseIndex].knowledgePoints.firstIndex(where: { $0.id == question.knowledgePointID })
        else { return }

        var point = courses[courseIndex].knowledgePoints[pointIndex]
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

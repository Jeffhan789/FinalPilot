import Foundation

final class FinalPilotStore: ObservableObject {
    @Published var courses: [Course]
    @Published var tasks: [StudyTask]
    @Published var careerEvents: [CareerEvent]
    @Published var attempts: [QuizAttempt]

    init(
        courses: [Course] = SeedData.courses,
        tasks: [StudyTask] = SeedData.tasks,
        careerEvents: [CareerEvent] = SeedData.careerEvents,
        attempts: [QuizAttempt] = []
    ) {
        self.courses = courses
        self.tasks = tasks
        self.careerEvents = careerEvents
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
        tasks[index].status = tasks[index].status == .done ? .pending : .done
    }

    func deferTask(_ task: StudyTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].status = .deferred
        tasks[index].bucket = .skip
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
    }

    func daysUntil(_ date: Date?) -> Int? {
        guard let date else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day
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
            subtitle: "根据刚才答题自动加入",
            minutes: confidence == .high ? 20 : 15,
            reason: confidence == .high ? "高自信错误比普通错误更危险。" : "错题需要在 24 小时内回看。",
            linkedCourseID: question.courseID,
            status: .pending
        )
        tasks.insert(task, at: 0)
    }

    private func bucketOrder(_ bucket: TaskBucket) -> Int {
        switch bucket {
        case .must: 0
        case .should: 1
        case .skip: 2
        }
    }
}


import Foundation
import UserNotifications

/// 复习提醒调度器，根据考试日期、知识点优先级、用户偏好自动计算提醒策略
/// 考试日期：C310 = 5/13、E320 = 5/14、C315 = 5/26
final class StudyReminderScheduler: ObservableObject {
    static let shared = StudyReminderScheduler()

    private let manager = NotificationManager.shared
    private let calendar = Calendar.current

    /// 三科考试日期（固定，与 SeedData 中课程保持一致）
    private let examDates: [(courseID: String, courseName: String, date: Date)] = [
        ("c310", "C310", Date.finalPilotDate(month: 5, day: 13, hour: 9)),
        ("e320", "E320", Date.finalPilotDate(month: 5, day: 14, hour: 9)),
        ("c315", "C315", Date.finalPilotDate(month: 5, day: 26, hour: 9))
    ]

    /// 默认提醒时段（9:00、14:00、20:00）
    private var defaultReminderHours: [Int] { reminderHoursFromStorage }

    /// 从 AppStorage 读取用户自定义时段
    private var reminderHoursFromStorage: [Int] {
        let hoursString = UserDefaults.standard.string(forKey: "finalPilot_reminderHours") ?? "9,14,20"
        return hoursString
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            .filter { (0...23).contains($0) }
    }

    private init() {}

    // MARK: - 主调度入口

    /// 重新计算并调度所有通知（在启动或数据变更时调用）
    /// 依赖 Store 中的知识点、课程数据
    func rescheduleAllNotifications(store: FinalPilotStore) {
        guard manager.isNotificationsEnabled else { return }

        // 1. 先取消所有旧通知
        manager.cancelAllPendingNotifications()

        // 2. 调度每日复习提醒（基于高优先级知识点）
        scheduleDailyStudyReminders(store: store)

        // 3. 调度考试倒计时提醒（1/3/7天）
        scheduleExamCountdownReminders()

        // 4. 调度每日统计推送（20:30）
        scheduleDailySummary(store: store)

        // 5. 调度错题回顾提醒（基于最近错题）
        scheduleMistakeReviewReminders(store: store)

        print("[StudyReminderScheduler] 所有通知已重新调度完成")
    }

    // MARK: - 每日复习提醒

    /// 根据高优先级知识点和考试日期，为每个提醒时段生成复习内容
    private func scheduleDailyStudyReminders(store: FinalPilotStore) {
        guard manager.isNotificationsEnabled else { return }

        let hours = defaultReminderHours
        guard !hours.isEmpty else { return }

        // 找到高优先级知识点（priority >= 5）或薄弱知识点
        let highPriorityCards = store.flashcards.filter { $0.priority >= 5 }
        let weakPoints = store.highRiskKnowledgePoints

        for (index, hour) in hours.enumerated() {
            let identifier = "daily_reminder_\(hour)"
            let content: (title: String, body: String)

            // 早晨提醒：侧重考试倒计时和今日任务
            if hour < 12 {
                let nearestExam = store.nearestExam
                let daysLeft = store.daysUntil(nearestExam?.examDate)
                let examName = nearestExam?.name ?? "考试"
                let mustCount = store.tasks(track: .exam, bucket: .must).filter { $0.status != .done }.count

                content.title = "🎓 学呀学 · 今日冲刺"
                if let days = daysLeft, days >= 0 {
                    content.body = "距离 \(examName) 还有 \(days) 天，今日有 \(mustCount) 个 Must 任务等你完成。开始复习吧！"
                } else {
                    content.body = "今日有 \(mustCount) 个 Must 任务等你完成，先保住 C310 / E320 优先级！"
                }
            }
            // 下午提醒：侧重复习薄弱知识点
            else if hour < 17 {
                if let firstCard = highPriorityCards.first {
                    content.title = "🔥 高优先级知识点复习"
                    content.body = "【\(firstCard.title)】\(firstCard.prompt.prefix(60))… 抽10分钟回顾一下吧！"
                } else if let firstWeak = weakPoints.first {
                    content.title = "⚠️ 薄弱知识点提醒"
                    content.body = "【\(firstWeak.1.title)】掌握度仅 \(Int(firstWeak.1.mastery * 100))%，建议优先复习！"
                } else {
                    content.title = "📚 下午复习时间"
                    content.body = "完成一套真题或复习辅导课笔记，保持手感！"
                }
            }
            // 晚上提醒：错题回顾和总结
            else {
                let todayAttempts = store.attempts.filter {
                    calendar.isDate($0.createdAt, inSameDayAs: Date())
                }
                let wrongCount = todayAttempts.filter { !$0.isCorrect }.count
                if wrongCount > 0 {
                    content.title = "🌙 晚间错题回顾"
                    content.body = "今天错了 \(wrongCount) 道题，睡前花15分钟复盘，效果翻倍！"
                } else {
                    content.title = "🌙 今日复习总结"
                    content.body = "今天表现不错！再花10分钟过一遍高频考点，巩固记忆。"
                }
            }

            manager.scheduleDailyReminder(
                identifier: identifier,
                title: content.title,
                body: content.body,
                hour: hour,
                minute: 0,
                category: NotificationCategory.studyReminder,
                userInfo: ["slotIndex": index]
            )
        }
    }

    // MARK: - 考试倒计时提醒

    /// 在考试前 1、3、7 天分别发送倒计时提醒
    private func scheduleExamCountdownReminders() {
        guard manager.countdownAlertsEnabled else { return }

        let now = Date()
        let countdownDays = [1, 3, 7]

        for exam in examDates {
            guard exam.date > now else { continue }

            for daysBefore in countdownDays {
                guard let reminderDate = calendar.date(byAdding: .day, value: -daysBefore, to: exam.date) else { continue }
                guard reminderDate > now else { continue }

                let identifier = "countdown_\(exam.courseID)_\(daysBefore)"
                let content = NotificationContent.examCountdown(
                    courseName: exam.courseName,
                    daysLeft: daysBefore,
                    examDate: exam.date
                )

                // 倒计时提醒在当天 8:00 发送
                var components = calendar.dateComponents([.year, .month, .day], from: reminderDate)
                components.hour = 8
                components.minute = 0
                guard let triggerDate = calendar.date(from: components) else { continue }

                manager.scheduleOneTimeReminder(
                    identifier: identifier,
                    title: content.title,
                    body: content.body,
                    date: triggerDate,
                    category: NotificationCategory.examCountdown,
                    userInfo: [
                        NotificationUserInfoKey.courseID: exam.courseID,
                        NotificationUserInfoKey.examDate: exam.date.timeIntervalSince1970,
                        NotificationUserInfoKey.daysUntilExam: daysBefore
                    ]
                )
            }

            // 考试当天提醒（考前 1 小时）
            let examDayIdentifier = "exam_day_\(exam.courseID)"
            guard let examDayReminder = calendar.date(byAdding: .hour, value: -1, to: exam.date) else { return }

            manager.scheduleOneTimeReminder(
                identifier: examDayIdentifier,
                title: "🚨 \(exam.courseName) 考试即将开始",
                body: "考试将在 1 小时后开始！带好准考证、身份证和文具，深呼吸，加油！",
                date: examDayReminder,
                category: NotificationCategory.examCountdown,
                userInfo: [
                    NotificationUserInfoKey.courseID: exam.courseID,
                    NotificationUserInfoKey.examDate: exam.date.timeIntervalSince1970
                ]
            )
        }
    }

    // MARK: - 每日统计推送

    /// 每天 20:30 推送学习统计摘要
    private func scheduleDailySummary(store: FinalPilotStore) {
        guard manager.dailySummaryEnabled else { return }

        let totalMinutes = store.totalStudyMinutes
        let completedTasks = store.tasks.filter { $0.status == .done }.count
        let totalTasks = store.tasks.filter { $0.bucket != .skip }.count
        let completionRate = Int(store.completionRate * 100)

        let content = NotificationContent.dailySummary(
            studyMinutes: totalMinutes,
            completedTasks: completedTasks,
            totalTasks: totalTasks,
            completionRate: completionRate
        )

        manager.scheduleDailyReminder(
            identifier: "daily_summary",
            title: content.title,
            body: content.body,
            hour: 20,
            minute: 30,
            category: NotificationCategory.dailySummary,
            userInfo: [
                "studyMinutes": totalMinutes,
                "completedTasks": completedTasks,
                "completionRate": completionRate
            ]
        )
    }

    // MARK: - 错题回顾提醒

    /// 基于最近错题，在 24 小时后发送回顾提醒（利用间隔重复效应）
    private func scheduleMistakeReviewReminders(store: FinalPilotStore) {
        let wrongAttempts = store.attempts.filter { !$0.isCorrect }.prefix(5)

        for (index, attempt) in wrongAttempts.enumerated() {
            // 错开发送时间，避免通知轰炸
            let delayMinutes = 60 + (index * 30)
            guard let question = store.allQuestions.first(where: { $0.id == attempt.questionID }) else { continue }

            let identifier = "mistake_review_\(attempt.id)"
            let content = NotificationContent.mistakeReview(
                questionSource: question.sourceType.label,
                sourceTitle: question.sourceTitle
            )

            manager.scheduleMistakeReviewReminder(
                identifier: identifier,
                title: content.title,
                body: content.body,
                afterMinutes: delayMinutes,
                userInfo: [
                    NotificationUserInfoKey.questionID: attempt.questionID,
                    NotificationUserInfoKey.knowledgePointID: attempt.knowledgePointID
                ]
            )
        }
    }

    // MARK: - 即时通知（用户操作触发）

    /// 用户完成一个 Must 任务后，发送即时鼓励通知
    func sendTaskCompletionEncouragement(task: StudyTask) {
        guard manager.isNotificationsEnabled else { return }
        let content = NotificationContent.taskCompleted(taskTitle: task.title)
        manager.sendImmediateNotification(
            title: content.title,
            body: content.body,
            userInfo: [NotificationUserInfoKey.taskID: task.id]
        )
    }

    /// 用户连续答对 3 题后，发送即时鼓励
    func sendStreakEncouragement(correctCount: Int) {
        guard manager.isNotificationsEnabled, correctCount >= 3 else { return }
        let content = NotificationContent.streakEncouragement(correctCount: correctCount)
        manager.sendImmediateNotification(
            title: content.title,
            body: content.body
        )
    }

    // MARK: - 用户偏好更新

    /// 更新用户自定义提醒时段并重新调度
    func updateReminderHours(_ hours: [Int], store: FinalPilotStore) {
        let sortedHours = hours.filter { (0...23).contains($0) }.sorted()
        let hoursString = sortedHours.map { String($0) }.joined(separator: ",")
        UserDefaults.standard.set(hoursString, forKey: "finalPilot_reminderHours")
        rescheduleAllNotifications(store: store)
    }
}

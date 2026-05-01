import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: FinalPilotStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    metricRow
                    examTrack
                    careerTrack
                    conflictPanel
                    skipPanel
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("今日冲刺")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Exam Sprint Mode")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                    Text("考试优先，面试保温")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.ink)
                    Text("先守住 C310/E320，再把 C315 放到 5 月 14 后推进。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "bolt.horizontal.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.orange)
            }

            if let nearest = store.nearestExam {
                HStack {
                    Label(nearest.name, systemImage: nearest.symbol)
                    Spacer()
                    Text(countdownText(for: nearest))
                        .font(.headline)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .padding(12)
                .background(AppTheme.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var metricRow: some View {
        HStack(spacing: 10) {
            MetricTile(title: "完成率", value: "\(Int(store.completionRate * 100))%", icon: "checkmark.seal", color: AppTheme.green)
            MetricTile(title: "薄弱点", value: "\(store.highRiskKnowledgePoints.count)", icon: "exclamationmark.triangle", color: AppTheme.orange)
            MetricTile(title: "已完成", value: "\(store.totalStudyMinutes)m", icon: "timer", color: AppTheme.primary)
        }
    }

    private var examTrack: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Exam Track", subtitle: "Must 任务优先，先处理高风险知识点")
            ForEach(store.tasks(track: .exam, bucket: .must)) { task in
                TaskCard(task: task) {
                    store.toggleTask(task)
                }
            }

            let shouldTasks = store.tasks(track: .exam, bucket: .should)
            if !shouldTasks.isEmpty {
                SectionHeader(title: "Exam Should", subtitle: "有余力再补，避免平均用力")
                ForEach(shouldTasks) { task in
                    TaskCard(task: task) {
                        store.toggleTask(task)
                    } onDefer: {
                        store.deferTask(task)
                    }
                }
            }
        }
    }

    private var careerTrack: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Career Minimum", subtitle: "校招只保留 15-30 分钟高收益任务")
            ForEach(store.tasks(track: .career, bucket: .should)) { task in
                TaskCard(task: task) {
                    store.toggleTask(task)
                } onDefer: {
                    store.deferTask(task)
                }
            }
        }
    }

    private var conflictPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "冲突提醒", subtitle: "ConflictAgent 当前建议")
            VStack(alignment: .leading, spacing: 8) {
                Label("C310 先考，今天必须把 Agent 基础和 Q1 真题入口打通。", systemImage: "exclamationmark.shield")
                Label("E320 只晚一天，每天至少保留一个公式/算法闭环。", systemImage: "arrow.triangle.merge")
                Label("C315 是 5 月 26 日，5 月 14 前不抢 C310/E320 主时间。", systemImage: "calendar.badge.clock")
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.ink)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var skipPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "今天不建议做", subtitle: "把低收益任务明确放下")
            ForEach(skipTasks) { task in
                TaskCard(task: task) {
                    store.toggleTask(task)
                }
            }
        }
    }

    private var skipTasks: [StudyTask] {
        store.tasks
            .filter { $0.bucket == .skip }
            .sorted { $0.minutes > $1.minutes }
    }

    private func countdownText(for course: Course) -> String {
        guard let days = store.daysUntil(course.examDate) else {
            return "保温复习"
        }
        if days <= 0 {
            return "今天考试"
        }
        return "\(days) 天后考试"
    }
}

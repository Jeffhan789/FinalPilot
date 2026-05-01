import Charts
import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var store: FinalPilotStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "冲刺分析", subtitle: "用数据判断今天的时间该往哪里放")
                    metricRow
                    masteryChart
                    riskList
                    workloadPanel
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("分析")
        }
    }

    private var metricRow: some View {
        HStack(spacing: 10) {
            MetricTile(title: "考试风险", value: "\(riskLevel)", icon: "exclamationmark.octagon", color: AppTheme.orange)
            MetricTile(title: "面试覆盖", value: "\(careerCoverage)%", icon: "briefcase", color: AppTheme.primary)
            MetricTile(title: "任务完成", value: "\(Int(store.completionRate * 100))%", icon: "checkmark.seal", color: AppTheme.green)
        }
    }

    private var masteryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "课程掌握度", subtitle: "低掌握度 + 近考试日期会进入 Must")
            Chart(store.courses) { course in
                BarMark(
                    x: .value("课程", course.name),
                    y: .value("掌握度", course.masteryAverage)
                )
                .foregroundStyle(AppTheme.courseColor(course.colorKey))
            }
            .chartYScale(domain: 0...1)
            .frame(height: 220)
            .padding(12)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var riskList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "高风险知识点", subtitle: "优先处理，不再平均复习")
            ForEach(store.highRiskKnowledgePoints.prefix(6), id: \.1.id) { course, point in
                HStack(spacing: 12) {
                    Image(systemName: course.symbol)
                        .foregroundStyle(AppTheme.courseColor(course.colorKey))
                        .frame(width: 30, height: 30)
                        .background(AppTheme.courseColor(course.colorKey).opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(point.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("\(course.name) · 掌握度 \(Int(point.mastery * 100))%")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Spacer()

                    Text(point.status.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.orange)
                }
                .padding(12)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var workloadPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "双轨负载", subtitle: "考试任务压住主线，校招保留短任务")
            HStack(spacing: 10) {
                workloadTile(title: "Exam", minutes: store.tasks(track: .exam).reduce(0) { $0 + $1.minutes }, color: AppTheme.orange)
                workloadTile(title: "Career", minutes: store.tasks(track: .career).filter { $0.bucket != .skip }.reduce(0) { $0 + $1.minutes }, color: AppTheme.primary)
            }
        }
    }

    private func workloadTile(title: String, minutes: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
            Text("\(minutes) 分钟")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            ProgressView(value: min(Double(minutes) / 120.0, 1))
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private var riskLevel: String {
        let weakCount = store.highRiskKnowledgePoints.count
        if weakCount >= 6 { return "高" }
        if weakCount >= 3 { return "中" }
        return "低"
    }

    private var careerCoverage: Int {
        let careerTasks = store.tasks(track: .career).filter { $0.bucket != .skip }
        guard !careerTasks.isEmpty else { return 0 }
        let doneOrPending = careerTasks.filter { $0.status != .deferred }.count
        return Int(Double(doneOrPending) / Double(careerTasks.count) * 100)
    }
}

import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

struct TaskCard: View {
    let task: StudyTask
    let onToggle: () -> Void
    var onDefer: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: task.track.icon)
                    .font(.headline)
                    .foregroundStyle(AppTheme.bucketColor(task.bucket))
                    .frame(width: 28, height: 28)
                    .background(AppTheme.bucketColor(task.bucket).opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(task.subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Text("\(task.minutes) 分钟")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.bucketColor(task.bucket))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppTheme.bucketColor(task.bucket).opacity(0.12), in: Capsule())
            }

            Text(task.reason)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)

            HStack {
                Button(action: onToggle) {
                    Label(task.status == .done ? "已完成" : "完成", systemImage: task.status == .done ? "checkmark.circle.fill" : "circle")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(task.status == .done ? AppTheme.green : AppTheme.primary)

                if let onDefer, task.bucket != .skip {
                    Button(action: onDefer) {
                        Label("延期", systemImage: "clock.arrow.circlepath")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.secondaryText)
                }
            }
        }
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.bucketColor(task.bucket).opacity(0.14))
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = AppTheme.primary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12), in: Circle())
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CourseCard: View {
    let course: Course
    let daysUntilExam: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: course.symbol)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.courseColor(course.colorKey), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(course.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text(examText)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Text("\(Int(course.masteryAverage * 100))%")
                    .font(.headline)
                    .foregroundStyle(AppTheme.courseColor(course.colorKey))
            }

            ProgressView(value: course.masteryAverage)
                .tint(AppTheme.courseColor(course.colorKey))

            HStack {
                Label("\(course.knowledgePoints.count) 知识点", systemImage: "square.grid.2x2")
                Spacer()
                Label("\(course.weakPoints.count) 薄弱", systemImage: "exclamationmark.triangle")
            }
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var examText: String {
        guard let daysUntilExam else {
            return "项目展示与知识保温"
        }
        if daysUntilExam <= 0 {
            return "考试日"
        }
        return "距离考试 \(daysUntilExam) 天"
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(AppTheme.secondaryText)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}


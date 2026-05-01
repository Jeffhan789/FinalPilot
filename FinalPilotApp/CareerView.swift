import SwiftUI

struct CareerView: View {
    @EnvironmentObject private var store: FinalPilotStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "校招保温", subtitle: "C310/E320 考前只做最低准备，不展开大工程")
                    nextInterview
                    minimumPack
                    projectPitch
                    careerTimeline
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("校招")
            .toolbar {
                Button {
                    store.addMockInterview()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var nextInterview: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "下一场面试", subtitle: "如与考试冲突，只保留最低准备包")

            if let event = store.careerEvents.sorted(by: { $0.date < $1.date }).first {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(event.company)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(AppTheme.ink)
                            Text("\(event.role) · \(event.round)")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Spacer()
                        Text(eventDateText(event.date))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary.opacity(0.12), in: Capsule())
                    }

                    Label(event.preparationStatus, systemImage: "checklist")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.ink)
                }
                .padding(16)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var minimumPack: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Career Minimum Pack", subtitle: "突发面试前至少有这 5 件东西")
            let items = [
                ("1 分钟自我介绍", "person.text.rectangle"),
                ("2 分钟 学呀学 项目介绍", "app.badge"),
                ("3 个技术亮点：多智能体、云端、掌握度预测", "sparkles"),
                ("3 个常见问题回答", "questionmark.bubble"),
                ("1 个反问面试官的问题", "arrowshape.turn.up.left")
            ]
            ForEach(items, id: \.0) { title, icon in
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 28, height: 28)
                        .background(AppTheme.primary.opacity(0.1), in: Circle())
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                }
                .padding(12)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var projectPitch: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "项目讲解卡", subtitle: "校招展示时按这个顺序讲")
            VStack(alignment: .leading, spacing: 12) {
                pitchLine(number: "1", title: "背景", text: "期末考试和校招面试并行，用户需要冲刺调度。")
                pitchLine(number: "2", title: "核心", text: "Exam Track 优先，Career Track 保温。")
                pitchLine(number: "3", title: "技术", text: "SwiftUI + 云端同步 + 多智能体 + 掌握度预测。")
                pitchLine(number: "4", title: "亮点", text: "ConflictAgent 自动处理任务冲突。")
            }
            .padding(16)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var careerTimeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "面试时间线", subtitle: "MVP 暂时手动维护，后续再接日历或邮箱")
            ForEach(store.careerEvents.sorted(by: { $0.date < $1.date })) { event in
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(event.company) · \(event.round)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text(eventDateText(event.date))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    Text("重要度 \(event.importance)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.orange)
                }
                .padding(12)
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func pitchLine(number: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(AppTheme.primary, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func eventDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

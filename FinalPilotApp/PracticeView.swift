import SwiftUI

struct PracticeView: View {
    @EnvironmentObject private var store: FinalPilotStore
    @State private var selectedCourseID: String?
    @State private var selectedAnswer: String?
    @State private var confidence: ConfidenceLevel = .medium
    @State private var feedback: QuizAttempt?
    @State private var questionIndex = 0

    private var selectedCourse: Course? {
        guard let selectedCourseID else { return store.courses.first }
        return store.courses.first { $0.id == selectedCourseID }
    }

    private var questions: [QuizQuestion] {
        selectedCourse?.questions ?? []
    }

    private var currentQuestion: QuizQuestion? {
        guard !questions.isEmpty else { return nil }
        return questions[questionIndex % questions.count]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "主动回忆练习", subtitle: "先答题，再看解释；答错会自动生成复盘任务")
                    coursePicker

                    if let question = currentQuestion {
                        questionCard(question)
                    } else {
                        EmptyStateView(title: "暂无题目", message: "下一版会从题库和上传资料生成更多题。", icon: "questionmark.circle")
                    }

                    recentAttempts
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("练习")
            .onAppear {
                selectedCourseID = selectedCourseID ?? store.courses.first?.id
            }
        }
    }

    private var coursePicker: some View {
        Picker("课程", selection: Binding(
            get: { selectedCourseID ?? store.courses.first?.id ?? "" },
            set: {
                selectedCourseID = $0
                questionIndex = 0
                selectedAnswer = nil
                feedback = nil
            }
        )) {
            ForEach(store.courses) { course in
                Text(course.name).tag(course.id)
            }
        }
        .pickerStyle(.segmented)
    }

    private func questionCard(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(question.difficulty.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
                Spacer()
                Text(question.type == "true_false" ? "判断题" : "选择题")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Text(question.question)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 10) {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        selectedAnswer = option
                    } label: {
                        HStack {
                            Text(option)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            if selectedAnswer == option {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .foregroundStyle(selectedAnswer == option ? .white : AppTheme.ink)
                        .padding(12)
                        .background(selectedAnswer == option ? AppTheme.primary : AppTheme.background, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            Picker("自信度", selection: $confidence) {
                ForEach(ConfidenceLevel.allCases) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Button {
                guard let selectedAnswer else { return }
                feedback = store.submitAnswer(question: question, selectedAnswer: selectedAnswer, confidence: confidence)
            } label: {
                Label("提交答案", systemImage: "paperplane")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            .disabled(selectedAnswer == nil)

            if let feedback {
                feedbackPanel(question: question, attempt: feedback)
            }
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func feedbackPanel(question: QuizQuestion, attempt: QuizAttempt) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(attempt.isCorrect ? "答对了" : "需要复盘", systemImage: attempt.isCorrect ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(attempt.isCorrect ? AppTheme.green : AppTheme.orange)

            Text(question.explanation)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink)

            if !attempt.isCorrect && attempt.confidence == .high {
                Text("这是 Confidence Trap：你很确定但答错了，系统已经把它加入 Must 复盘。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.orange)
            }

            Button {
                questionIndex += 1
                selectedAnswer = nil
                feedback = nil
            } label: {
                Label("下一题", systemImage: "arrow.right.circle")
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.primary)
        }
        .padding(12)
        .background((attempt.isCorrect ? AppTheme.green : AppTheme.orange).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    private var recentAttempts: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "最近答题", subtitle: "用于后续掌握度预测")
            if store.attempts.isEmpty {
                EmptyStateView(title: "还没有答题记录", message: "完成一题后，这里会出现正确率和自信度信号。", icon: "tray")
            } else {
                ForEach(store.attempts.prefix(4)) { attempt in
                    HStack {
                        Image(systemName: attempt.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(attempt.isCorrect ? AppTheme.green : AppTheme.orange)
                        Text(attempt.selectedAnswer)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                        Spacer()
                        Text(attempt.confidence.label)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(12)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

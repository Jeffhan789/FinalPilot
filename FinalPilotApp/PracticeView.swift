import SwiftUI

private enum PracticeQuestionFilter: String, CaseIterable, Identifiable {
    case all
    case lecture
    case tutorial
    case pastPaper
    case finalExam

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "全部"
        case .lecture: "课件"
        case .tutorial: "辅导课"
        case .pastPaper: "真题"
        case .finalExam: "期末"
        }
    }

    var subtitle: String {
        switch self {
        case .all: "混合刷题，优先覆盖薄弱点"
        case .lecture: "把课件概念压成可答题的定义"
        case .tutorial: "对齐辅导课步骤题和例题"
        case .pastPaper: "按真题矩阵训练高频入口"
        case .finalExam: "只看期末高价值题型"
        }
    }

    func matches(_ question: QuizQuestion) -> Bool {
        switch self {
        case .all:
            return true
        case .lecture:
            return question.sourceType == .lecture || question.sourceType == .sprintNote
        case .tutorial:
            return question.sourceType == .tutorial
        case .pastPaper:
            return question.sourceType == .pastPaper
        case .finalExam:
            return question.sourceType == .finalExam
        }
    }
}

struct PracticeView: View {
    @EnvironmentObject private var store: FinalPilotStore
    @State private var selectedCourseID: String?
    @State private var selectedAnswer: String?
    @State private var selectedSourceFilter: PracticeQuestionFilter = .all
    @State private var confidence: ConfidenceLevel = .medium
    @State private var feedback: QuizAttempt?
    @State private var questionIndex = 0

    private let practiceCourseIDs: Set<String> = ["c310_multi_agent", "e320_neural_network"]
    private let currentStudyQuestionIDs: Set<String> = [
        "q_c310_001", "q_c310_002", "q_c310_003", "q_c310_004", "q_c310_005",
        "q_c310_006", "q_c310_007", "q_c310_008", "q_c310_009", "q_c310_015",
        "q_c310_023", "q_c310_024", "q_c310_025", "q_c310_026", "q_c310_027",
        "q_c310_028", "q_c310_029", "q_c310_030",
        "q_c310_031", "q_c310_032", "q_c310_033", "q_c310_034", "q_c310_035",
        "q_c310_036", "q_c310_037", "q_c310_038", "q_c310_039", "q_c310_040",
        "q_c310_041", "q_c310_042", "q_c310_043", "q_c310_044", "q_c310_045",
        "q_c310_046",
        "q_e320_002", "q_e320_003", "q_e320_004", "q_e320_005", "q_e320_006",
        "q_e320_012", "q_e320_015", "q_e320_016", "q_e320_017",
        "q_e320_023", "q_e320_024", "q_e320_025", "q_e320_026", "q_e320_027",
        "q_e320_028", "q_e320_029", "q_e320_030",
        "q_e320_031", "q_e320_032", "q_e320_033", "q_e320_034", "q_e320_035",
        "q_e320_036", "q_e320_037", "q_e320_038", "q_e320_039", "q_e320_040",
        "q_e320_041", "q_e320_042", "q_e320_043", "q_e320_044", "q_e320_045",
        "q_e320_046"
    ]

    private var practiceCourses: [Course] {
        store.courses.filter { practiceCourseIDs.contains($0.id) }
    }

    private var selectedCourse: Course? {
        guard let selectedCourseID else { return practiceCourses.first }
        return practiceCourses.first { $0.id == selectedCourseID } ?? practiceCourses.first
    }

    private var allCourseQuestions: [QuizQuestion] {
        selectedCourse?.questions.filter { currentStudyQuestionIDs.contains($0.id) } ?? []
    }

    private var questions: [QuizQuestion] {
        allCourseQuestions
            .filter { selectedSourceFilter.matches($0) }
            .sorted { lhs, rhs in
                if difficultyRank(lhs.difficulty) != difficultyRank(rhs.difficulty) {
                    return difficultyRank(lhs.difficulty) < difficultyRank(rhs.difficulty)
                }
                return lhs.examValue > rhs.examValue
            }
    }

    private var currentQuestion: QuizQuestion? {
        guard !questions.isEmpty else { return nil }
        return questions[questionIndex % questions.count]
    }

    private var selectedCourseAttempts: [QuizAttempt] {
        let questionIDs = Set(allCourseQuestions.map(\.id))
        return store.attempts.filter { questionIDs.contains($0.questionID) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "主动回忆练习", subtitle: "只检验 C310 / E320 前两天笔记和考试高频点的吸收程度")
                    coursePicker
                    sourceFilterPicker
                    practiceSummary

                    if let question = currentQuestion {
                        questionCard(question)
                    } else {
                        EmptyStateView(title: "当前模式暂无题目", message: "切换到全部模式，或继续把课程资料同步成新的题。", icon: "questionmark.circle")
                    }

                    recentAttempts
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("练习")
            .onAppear {
                selectedCourseID = selectedCourseID ?? practiceCourses.first?.id
            }
        }
    }

    private var coursePicker: some View {
        Picker("课程", selection: Binding(
            get: { selectedCourseID ?? practiceCourses.first?.id ?? "" },
            set: {
                selectedCourseID = $0
                resetQuestionFlow()
            }
        )) {
            ForEach(practiceCourses) { course in
                Text(course.name).tag(course.id)
            }
        }
        .pickerStyle(.segmented)
    }

    private var sourceFilterPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("题源", selection: Binding(
                get: { selectedSourceFilter },
                set: {
                    selectedSourceFilter = $0
                    resetQuestionFlow()
                }
            )) {
                ForEach(PracticeQuestionFilter.allCases) { filter in
                    Text(filter.label).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Label(selectedSourceFilter.subtitle, systemImage: "scope")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var practiceSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "target")
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.primary.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedCourse?.name ?? "课程题库")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("按笔记序号与考试价值由浅入深：定义、公式、BDI、STRIPS、感知器")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                summaryPill(title: "当前", value: "\(questions.count)/\(allCourseQuestions.count)")
                summaryPill(title: "高价值", value: "\(questions.filter { $0.examValue >= 5 }.count)")
                summaryPill(title: "正确率", value: accuracyText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var accuracyText: String {
        guard !selectedCourseAttempts.isEmpty else { return "--" }
        let correct = selectedCourseAttempts.filter(\.isCorrect).count
        let rate = Double(correct) / Double(selectedCourseAttempts.count)
        return "\(Int(rate * 100))%"
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppTheme.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func questionCard(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            questionHeader(question)

            Text(question.question)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            sourcePanel(question)

            VStack(spacing: 10) {
                ForEach(question.options, id: \.self) { option in
                    optionButton(option, for: question)
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
            .disabled(selectedAnswer == nil || feedback != nil)

            if let feedback {
                feedbackPanel(question: question, attempt: feedback)
            }
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func questionHeader(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(question.sourceType.label, systemImage: question.sourceType.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.questionSourceColor(question.sourceType))

                Spacer()

                Text("价值 \(question.examValue)/5")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.orange)
            }

            HStack(spacing: 8) {
                Text("第 \(currentQuestionNumber(for: question)) / \(questions.count) 题")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.orange)

                Text(question.difficulty.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primary)

                Text(questionKindLabel(question.type))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private func sourcePanel(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let point = knowledgePoint(for: question) {
                Label("考查知识点：\(point.title)", systemImage: "brain.head.profile")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(question.sourceTitle)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.ink)

            Text(question.sourceDetail)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Label(question.examPrompt, systemImage: "lightbulb")
                .font(.caption)
                .foregroundStyle(AppTheme.questionSourceColor(question.sourceType))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.questionSourceColor(question.sourceType).opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
    }

    private func optionButton(_ option: String, for question: QuizQuestion) -> some View {
        let background = optionBackground(option, for: question)
        let isEmphasized = selectedAnswer == option || (feedback != nil && option == question.answer)
        let foreground: Color = isEmphasized ? .white : AppTheme.ink

        return Button {
            guard feedback == nil else { return }
            selectedAnswer = option
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text(option)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                optionIcon(option, for: question)
            }
            .foregroundStyle(foreground)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(optionBorder(option, for: question), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func optionIcon(_ option: String, for question: QuizQuestion) -> some View {
        if feedback != nil && option == question.answer {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
        } else if let feedback, option == feedback.selectedAnswer, !feedback.isCorrect {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.white)
        } else if selectedAnswer == option {
            Image(systemName: "checkmark.circle.fill")
        }
    }

    private func optionBackground(_ option: String, for question: QuizQuestion) -> Color {
        if let feedback {
            if option == question.answer {
                return AppTheme.green
            }
            if option == feedback.selectedAnswer && !feedback.isCorrect {
                return AppTheme.orange
            }
        }
        if selectedAnswer == option {
            return AppTheme.primary
        }
        return AppTheme.background
    }

    private func optionBorder(_ option: String, for question: QuizQuestion) -> Color {
        if feedback != nil && option == question.answer {
            return AppTheme.green
        }
        if selectedAnswer == option {
            return AppTheme.primary.opacity(0.3)
        }
        return Color.clear
    }

    private func feedbackPanel(question: QuizQuestion, attempt: QuizAttempt) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(attempt.isCorrect ? "答对了" : "需要复盘", systemImage: attempt.isCorrect ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(attempt.isCorrect ? AppTheme.green : AppTheme.orange)

            Text(question.explanation)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if let point = knowledgePoint(for: question) {
                Label("考查：\(point.chapter) · \(point.title)", systemImage: "brain.head.profile")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Label(question.examPrompt, systemImage: "pencil.and.outline")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.questionSourceColor(question.sourceType))
                .fixedSize(horizontal: false, vertical: true)

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
            SectionHeader(title: "最近答题", subtitle: "记录正确率、自信度和题目来源")
            if selectedCourseAttempts.isEmpty {
                EmptyStateView(title: "还没有答题记录", message: "完成一题后，这里会出现正确率、自信度和资料来源。", icon: "tray")
            } else {
                ForEach(selectedCourseAttempts.prefix(5)) { attempt in
                    recentAttemptRow(attempt)
                }
            }
        }
    }

    private func recentAttemptRow(_ attempt: QuizAttempt) -> some View {
        let question = store.allQuestions.first { $0.id == attempt.questionID }
        let sourceType = question?.sourceType

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: attempt.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(attempt.isCorrect ? AppTheme.green : AppTheme.orange)

            VStack(alignment: .leading, spacing: 3) {
                Text(question?.sourceTitle ?? attempt.selectedAnswer)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text("\(sourceType?.label ?? "题目") · \(attempt.confidence.label) · \(attempt.selectedAnswer)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(12)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 8))
    }

    private func questionKindLabel(_ type: String) -> String {
        switch type {
        case "true_false": "判断题"
        case "self_check": "自评题"
        default: "选择题"
        }
    }

    private func knowledgePoint(for question: QuizQuestion) -> KnowledgePoint? {
        store.courses
            .first { $0.id == question.courseID }?
            .knowledgePoints
            .first { $0.id == question.knowledgePointID }
    }

    private func currentQuestionNumber(for question: QuizQuestion) -> Int {
        guard let index = questions.firstIndex(where: { $0.id == question.id }) else { return 1 }
        return index + 1
    }

    private func difficultyRank(_ difficulty: String) -> Int {
        switch difficulty {
        case "easy": 0
        case "medium": 1
        case "hard": 2
        default: 3
        }
    }

    private func resetQuestionFlow() {
        questionIndex = 0
        selectedAnswer = nil
        feedback = nil
        confidence = .medium
    }
}

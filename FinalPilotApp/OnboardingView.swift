import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme
    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "graduationcap.circle.fill",
                    title: "考试倒计时",
                    description: "精准追踪每门考试剩余天数，智能规划冲刺节奏，让备考心中有数",
                    accentColor: AppTheme.primary,
                    pageIndex: 0
                )
                .tag(0)

                OnboardingPage(
                    icon: "checklist.checked.circle.fill",
                    title: "任务管理",
                    description: "Must / Should / Skip 三级任务桶，自动排定优先级，高效管理每日学习",
                    accentColor: AppTheme.orange,
                    pageIndex: 1
                )
                .tag(1)

                OnboardingPage(
                    icon: "book.pages.fill",
                    title: "知识手卡",
                    description: "核心知识点碎片化记忆，随时随地快速复习，巩固考试重点",
                    accentColor: AppTheme.green,
                    pageIndex: 2
                )
                .tag(2)

                OnboardingPage(
                    icon: "target",
                    title: "练习测验",
                    description: "真题闭环、模拟考试，实时检验掌握程度，精准定位薄弱环节",
                    accentColor: AppTheme.primary,
                    pageIndex: 3
                )
                .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

            // Bottom Action Area
            VStack(spacing: 16) {
                if currentPage == totalPages - 1 {
                    Button(action: completeOnboarding) {
                        HStack(spacing: 8) {
                            Text("开始使用")
                                .font(.headline.weight(.semibold))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: nextPage) {
                        HStack(spacing: 6) {
                            Text("下一步")
                                .font(.headline.weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if currentPage < totalPages - 1 {
                    Button("跳过") {
                        completeOnboarding()
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(AppTheme.adaptiveBackground(forScheme: colorScheme))
        }
        .background(AppTheme.adaptiveBackground(forScheme: colorScheme))
    }

    private func nextPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentPage < totalPages - 1 {
                currentPage += 1
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            hasSeenOnboarding = true
        }
    }
}

// MARK: - Onboarding Page
struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let pageIndex: Int

    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated Icon Stack
            ZStack {
                // Background glow
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                // Secondary ring
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 2)
                    .frame(width: 180, height: 180)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isAnimating)

                // Decorative dots
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .offset(
                            x: 90 * cos(Double(index) * .pi / 3),
                            y: 90 * sin(Double(index) * .pi / 3)
                        )
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 1.5)
                                .delay(Double(index) * 0.1)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }

                // Main icon
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)
                    .offset(y: isAnimating ? -4 : 4)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppTheme.ink)

                Text(description)
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Onboarding Wrapper for App Entry
struct OnboardingWrapper: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
    }
}

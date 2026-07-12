import SwiftUI

// MARK: - Shimmer Effect Modifier
struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme

    private var shimmerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.4)
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            shimmerColor,
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2, height: geometry.size.height)
                    .offset(x: isAnimating ? geometry.size.width * 2 : -geometry.size.width * 2)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Base Shapes
struct SkeletonRectangle: View {
    var height: CGFloat = 16
    var width: CGFloat? = nil
    var cornerRadius: CGFloat = 4
    @Environment(\.colorScheme) private var colorScheme

    private var baseColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.25) : Color.gray.opacity(0.15)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(baseColor)
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 40
    @Environment(\.colorScheme) private var colorScheme

    private var baseColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.25) : Color.gray.opacity(0.15)
    }

    var body: some View {
        Circle()
            .fill(baseColor)
            .frame(width: size, height: size)
            .shimmer()
    }
}

struct SkeletonText: View {
    var lines: Int = 1
    var lineHeight: CGFloat = 16
    var lineSpacing: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(0..<lines, id: \.self) { line in
                SkeletonRectangle(
                    height: lineHeight,
                    width: line == lines - 1 && lines > 1 ? 120 : nil,
                    cornerRadius: lineHeight / 2
                )
            }
        }
    }
}

// MARK: - Card Skeletons
struct TaskCardSkeleton: View {
    @Environment(\.colorScheme) private var colorScheme

    private var baseColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.12)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SkeletonCircle(size: 28)
                VStack(alignment: .leading, spacing: 3) {
                    SkeletonRectangle(height: 16, width: 140)
                    SkeletonRectangle(height: 12, width: 100)
                }
                Spacer()
                SkeletonRectangle(height: 22, width: 60, cornerRadius: 11)
            }

            SkeletonRectangle(height: 28, width: nil)

            HStack(spacing: 8) {
                SkeletonRectangle(height: 32, width: 80, cornerRadius: 8)
                SkeletonRectangle(height: 32, width: 60, cornerRadius: 8)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CourseCardSkeleton: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SkeletonRectangle(height: 34, width: 34, cornerRadius: 8)
                VStack(alignment: .leading, spacing: 3) {
                    SkeletonRectangle(height: 18, width: 160)
                    SkeletonRectangle(height: 12, width: 120)
                }
                Spacer()
                SkeletonRectangle(height: 22, width: 50)
            }

            SkeletonRectangle(height: 4, width: nil, cornerRadius: 2)

            SkeletonRectangle(height: 16, width: 200)

            HStack {
                SkeletonRectangle(height: 14, width: 100)
                Spacer()
                SkeletonRectangle(height: 14, width: 80)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct MetricTileSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SkeletonCircle(size: 28)
            SkeletonRectangle(height: 22, width: 50)
            SkeletonRectangle(height: 12, width: 80)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CourseListSkeleton: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                CourseCardSkeleton()
            }
        }
    }
}

struct TaskListSkeleton: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                TaskCardSkeleton()
            }
        }
    }
}

struct DashboardSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header skeleton
            HStack {
                SkeletonRectangle(height: 24, width: 120)
                Spacer()
                SkeletonCircle(size: 32)
            }
            .padding(.horizontal)

            // Metric tiles skeleton
            HStack(spacing: 10) {
                MetricTileSkeleton()
                MetricTileSkeleton()
                MetricTileSkeleton()
            }
            .padding(.horizontal)

            // Section header
            SkeletonRectangle(height: 20, width: 80)
                .padding(.horizontal)

            // Task list skeleton
            TaskListSkeleton()
                .padding(.horizontal)
        }
    }
}

// MARK: - Loading State Container
struct LoadingSkeleton<Content: View>: View {
    let isLoading: Bool
    let content: Content
    let skeleton: AnyView

    init(isLoading: Bool, @ViewBuilder content: () -> Content, @ViewBuilder skeleton: () -> some View) {
        self.isLoading = isLoading
        self.content = content()
        self.skeleton = AnyView(skeleton())
    }

    var body: some View {
        if isLoading {
            skeleton
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        } else {
            content
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }
}

// MARK: - Redacted Skeleton Helper
struct RedactedSkeleton: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .shimmer()
    }
}

extension View {
    func redactedSkeleton() -> some View {
        modifier(RedactedSkeleton())
    }
}

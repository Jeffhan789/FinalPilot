import SwiftUI

// MARK: - Dynamic Color Helpers
extension Color {
    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            default:
                return light
            }
        })
    }
}

// MARK: - AppTheme
enum AppTheme {
    // MARK: Base Colors
    static let primary = Color(light: UIColor(red: 0.15, green: 0.43, blue: 0.46, alpha: 1.0),
                               dark: UIColor(red: 0.40, green: 0.72, blue: 0.75, alpha: 1.0))
    static let orange = Color(light: UIColor(red: 0.91, green: 0.55, blue: 0.25, alpha: 1.0),
                              dark: UIColor(red: 1.00, green: 0.70, blue: 0.35, alpha: 1.0))
    static let green = Color(light: UIColor(red: 0.18, green: 0.62, blue: 0.40, alpha: 1.0),
                             dark: UIColor(red: 0.35, green: 0.78, blue: 0.55, alpha: 1.0))
    static let ink = Color(light: UIColor(red: 0.12, green: 0.16, blue: 0.20, alpha: 1.0),
                           dark: UIColor(red: 0.92, green: 0.94, blue: 0.96, alpha: 1.0))
    static let secondaryText = Color(light: UIColor(red: 0.42, green: 0.45, blue: 0.50, alpha: 1.0),
                                     dark: UIColor(red: 0.60, green: 0.63, blue: 0.68, alpha: 1.0))
    static let background = Color(light: UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0),
                                  dark: UIColor(red: 0.08, green: 0.10, blue: 0.12, alpha: 1.0))
    static let card = Color(light: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
                            dark: UIColor(red: 0.15, green: 0.17, blue: 0.20, alpha: 1.0))

    // MARK: Semantic Colors
    static let error = Color(light: UIColor(red: 0.85, green: 0.25, blue: 0.20, alpha: 1.0),
                             dark: UIColor(red: 1.00, green: 0.40, blue: 0.35, alpha: 1.0))
    static let warning = Color(light: UIColor(red: 0.90, green: 0.70, blue: 0.15, alpha: 1.0),
                               dark: UIColor(red: 1.00, green: 0.85, blue: 0.35, alpha: 1.0))
    static let success = Color(light: UIColor(red: 0.20, green: 0.70, blue: 0.35, alpha: 1.0),
                               dark: UIColor(red: 0.40, green: 0.85, blue: 0.55, alpha: 1.0))

    // MARK: Surface Colors
    static let elevatedCard = Color(light: UIColor(red: 0.99, green: 0.99, blue: 1.00, alpha: 1.0),
                                    dark: UIColor(red: 0.20, green: 0.22, blue: 0.25, alpha: 1.0))
    static let groupedBackground = Color(light: UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0),
                                         dark: UIColor(red: 0.10, green: 0.12, blue: 0.14, alpha: 1.0))
    static let separator = Color(light: UIColor(red: 0.88, green: 0.89, blue: 0.90, alpha: 1.0),
                                 dark: UIColor(red: 0.25, green: 0.27, blue: 0.30, alpha: 1.0))

    // MARK: Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.8), primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var warmGradient: LinearGradient {
        LinearGradient(
            colors: [orange.opacity(0.7), orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var successGradient: LinearGradient {
        LinearGradient(
            colors: [green.opacity(0.7), green],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [card, card.opacity(0.95)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.15), orange.opacity(0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var darkOverlayGradient: LinearGradient {
        LinearGradient(
            colors: [Color.black.opacity(0.0), Color.black.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Dynamic Helpers
    static func adaptiveBackground(forScheme scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.08, green: 0.10, blue: 0.12) : Color(red: 0.96, green: 0.97, blue: 0.98)
    }

    static func adaptiveCard(forScheme scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.15, green: 0.17, blue: 0.20) : Color.white
    }

    static func adaptiveInk(forScheme scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.92, green: 0.94, blue: 0.96) : Color(red: 0.12, green: 0.16, blue: 0.20)
    }

    // MARK: Existing Helpers (Enhanced for Dark Mode)
    static func courseColor(_ key: String) -> Color {
        switch key {
        case "blue": Color(light: UIColor(red: 0.18, green: 0.42, blue: 0.78, alpha: 1.0),
                           dark: UIColor(red: 0.40, green: 0.62, blue: 1.00, alpha: 1.0))
        case "orange": orange
        default: primary
        }
    }

    static func bucketColor(_ bucket: TaskBucket) -> Color {
        switch bucket {
        case .must: orange
        case .should: primary
        case .skip: secondaryText
        }
    }

    static func phaseColor(_ phase: SprintPlanPhase) -> Color {
        switch phase {
        case .foundation: primary
        case .highFrequency: orange
        case .pastPaper: Color(light: UIColor(red: 0.18, green: 0.42, blue: 0.78, alpha: 1.0),
                               dark: UIColor(red: 0.40, green: 0.62, blue: 1.00, alpha: 1.0))
        case .examSwitch: green
        }
    }

    static func questionSourceColor(_ source: QuestionSourceType) -> Color {
        switch source {
        case .lecture: primary
        case .tutorial: green
        case .pastPaper: Color(light: UIColor(red: 0.18, green: 0.42, blue: 0.78, alpha: 1.0),
                               dark: UIColor(red: 0.40, green: 0.62, blue: 1.00, alpha: 1.0))
        case .finalExam: orange
        case .sprintNote: Color(light: UIColor(red: 0.48, green: 0.36, blue: 0.72, alpha: 1.0),
                                 dark: UIColor(red: 0.68, green: 0.56, blue: 0.92, alpha: 1.0))
        }
    }

    // MARK: Shadows
    static func cardShadow(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.06)
    }

    static func elevatedShadow(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.4) : Color.black.opacity(0.10)
    }

    // MARK: Typography Helpers
    static func sectionTitle(colorScheme: ColorScheme) -> Color {
        adaptiveInk(forScheme: colorScheme)
    }

    static func bodyText(colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.75, green: 0.77, blue: 0.80) : secondaryText
    }
}

// MARK: - View Modifiers for Theme
struct ThemedBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppTheme.adaptiveBackground(forScheme: colorScheme))
    }
}

struct ThemedCardBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(AppTheme.adaptiveCard(forScheme: colorScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ThemedShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .shadow(color: AppTheme.cardShadow(colorScheme: colorScheme), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackground())
    }

    func themedCard() -> some View {
        modifier(ThemedCardBackground())
    }

    func themedShadow() -> some View {
        modifier(ThemedShadow())
    }
}

// MARK: - Color Scheme Preview Helper
struct ColorSchemePreview<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
                .preferredColorScheme(.light)
                .frame(height: 200)
                .clipped()

            Divider()

            content
                .preferredColorScheme(.dark)
                .frame(height: 200)
                .clipped()
        }
    }
}

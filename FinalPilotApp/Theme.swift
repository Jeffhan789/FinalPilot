import SwiftUI

enum AppTheme {
    static let primary = Color(red: 0.15, green: 0.43, blue: 0.46)
    static let orange = Color(red: 0.91, green: 0.55, blue: 0.25)
    static let green = Color(red: 0.18, green: 0.62, blue: 0.4)
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.2)
    static let secondaryText = Color(red: 0.42, green: 0.45, blue: 0.5)
    static let background = Color(red: 0.96, green: 0.97, blue: 0.98)
    static let card = Color.white

    static func courseColor(_ key: String) -> Color {
        switch key {
        case "blue": Color(red: 0.18, green: 0.42, blue: 0.78)
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
        case .pastPaper: Color(red: 0.18, green: 0.42, blue: 0.78)
        case .examSwitch: green
        }
    }

    static func questionSourceColor(_ source: QuestionSourceType) -> Color {
        switch source {
        case .lecture: primary
        case .tutorial: green
        case .pastPaper: Color(red: 0.18, green: 0.42, blue: 0.78)
        case .finalExam: orange
        case .sprintNote: Color(red: 0.48, green: 0.36, blue: 0.72)
        }
    }
}

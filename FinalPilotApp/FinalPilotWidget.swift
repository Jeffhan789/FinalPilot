import WidgetKit
import SwiftUI

// MARK: - WidgetBundle
// 使用 @main 注册所有 FinalPilot 小组件

@main
struct FinalPilotWidgetBundle: WidgetBundle {
    var body: some Widget {
        ExamCountdownWidget()
        TodayTasksWidget()
        DailyProgressWidget()
    }
}

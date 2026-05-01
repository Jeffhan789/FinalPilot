import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("今日", systemImage: "bolt.horizontal.circle")
                }

            CoursesView()
                .tabItem {
                    Label("课程", systemImage: "books.vertical")
                }

            PracticeView()
                .tabItem {
                    Label("练习", systemImage: "checklist.checked")
                }

            AnalyticsView()
                .tabItem {
                    Label("分析", systemImage: "chart.xyaxis.line")
                }

            CareerView()
                .tabItem {
                    Label("校招", systemImage: "briefcase")
                }
        }
        .tint(AppTheme.primary)
    }
}

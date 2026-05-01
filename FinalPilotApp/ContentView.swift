import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("今日", systemImage: "bolt.horizontal.circle")
                }

            PlanView()
                .tabItem {
                    Label("计划", systemImage: "calendar.badge.clock")
                }

            PracticeView()
                .tabItem {
                    Label("练习", systemImage: "checklist.checked")
                }

            CoursesView()
                .tabItem {
                    Label("课程", systemImage: "books.vertical")
                }
        }
        .tint(AppTheme.primary)
    }
}

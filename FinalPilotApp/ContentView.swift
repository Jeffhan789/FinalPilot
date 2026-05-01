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

            CoursesView()
                .tabItem {
                    Label("课程", systemImage: "books.vertical")
                }

            PracticeView()
                .tabItem {
                    Label("练习", systemImage: "checklist.checked")
                }

            CareerView()
                .tabItem {
                    Label("校招", systemImage: "briefcase")
                }
        }
        .tint(AppTheme.primary)
    }
}

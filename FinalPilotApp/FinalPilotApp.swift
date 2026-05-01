import SwiftUI

@main
struct FinalPilotApp: App {
    @StateObject private var store = FinalPilotStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}


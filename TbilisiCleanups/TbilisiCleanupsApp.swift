import Firebase
import SwiftUI

@main
struct TbilisiCleanupsApp: App {

    @StateObject private var appState: AppState = .init()

    init() {
        if ProcessInfo.processInfo.environment["ENABLE_PREVIEWS"] == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

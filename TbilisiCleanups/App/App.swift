import Firebase
import SwiftUI

@main
struct TbilisiCleanupsApp: App {
    @UIApplicationDelegateAdaptor private var delegate: AppDelegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        if ProcessInfo.processInfo.environment["ENABLE_PREVIEWS"] == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(delegate.appState)
                .environmentObject(delegate.appState.userState)
                .environmentObject(delegate.userService)
                .environmentObject(delegate.reportService)
                .environmentObject(delegate.stateRestorationService)
        }
        .onChange(of: scenePhase) { newValue in
            switch newValue {
            case .active:
                delegate.getNotificationsSettings()
            case .inactive:
                break
            case .background:
                try? delegate.stateRestorationService.saveState()
            @unknown default:
                break
            }
        }
    }
}

import Firebase
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        if ProcessInfo.processInfo.environment["ENABLE_PREVIEWS"] == nil {
            FirebaseApp.configure()
            UIApplication.shared.registerForRemoteNotifications()
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // no-op
    }
}

@main
struct TbilisiCleanupsApp: App {

    @UIApplicationDelegateAdaptor private var delegate: AppDelegate

    @StateObject private var appState: AppState = .init()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appState.currentDraft)
                .environmentObject(appState.userState)
        }
    }
}

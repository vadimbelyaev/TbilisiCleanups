import Firebase
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {

    let appState: AppState = .init()
    private(set) lazy var authService: AuthService = .init(userState: appState.userState)
    private(set) lazy var reportService: ReportService = .init(appState: appState)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        if ProcessInfo.processInfo.environment["ENABLE_PREVIEWS"] == nil {
            FirebaseApp.configure()

            // Ensuring the service is created as early as possible
            // because it listens to the user authentication changes
            let _ = authService

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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(delegate.appState)
                .environmentObject(delegate.appState.userState)
                .environmentObject(delegate.authService)
                .environmentObject(delegate.reportService)
        }
    }
}

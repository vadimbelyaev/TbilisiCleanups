import Combine
import Firebase
import SwiftUI

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    let appState: AppState = .init()
    private(set) lazy var authService = AuthService(appState: appState)
    private(set) lazy var reportService = ReportService(appState: appState)
    private(set) lazy var stateRestorationService = StateRestorationService(appState: appState)

    private var cancellables: Set<AnyCancellable> = []

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        guard ProcessInfo.processInfo.environment["ENABLE_PREVIEWS"] == nil else {
            return true
        }
        FirebaseApp.configure()

        // Ensuring the service is created as early as possible
        // because it listens to the user authentication changes
        _ = authService

        setUpGlobalSubscriptions()
        UIApplication.shared.registerForRemoteNotifications()
        try? stateRestorationService.restoreState()
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // no-op
    }

    // MARK: - Private

    private func setUpGlobalSubscriptions() {
        let reportService = self.reportService
        let appState = self.appState
        authService.userPublisher
            .receive(on: DispatchQueue.main)
            .sink { user in
                if let user = user, !user.isAnonymous {
                    Task.detached(priority: .low) {
                        try await reportService.fetchReportsByCurrentUser()
                    }
                } else {
                    appState.userReports = []
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - App

@main
struct TbilisiCleanupsApp: App {
    @UIApplicationDelegateAdaptor private var delegate: AppDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(delegate.appState)
                .environmentObject(delegate.appState.userState)
                .environmentObject(delegate.authService)
                .environmentObject(delegate.reportService)
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .background {
                try? delegate.stateRestorationService.saveState()
            }
        }
    }
}

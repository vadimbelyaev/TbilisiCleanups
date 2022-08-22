import Combine
import Firebase
import os.log
import SwiftUI

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    let appState: AppState = .init()
    private(set) lazy var authService = AuthService(appState: appState)
    private(set) lazy var reportService = ReportService(appState: appState)
    private(set) lazy var stateRestorationService = StateRestorationService(appState: appState)

    private var cancellables: Set<AnyCancellable> = []

    private let logger = Logger(subsystem: "net.vadimbelyaev.TbilisiCleanups", category: "AppDelegate")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        guard ProcessInfo.processInfo.environment["ENABLE_PREVIEWS"] == nil else {
            return true
        }
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        // Ensuring the service is created as early as possible
        // because it listens to the user authentication changes
        _ = authService

        setUpGlobalSubscriptions()
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        try? stateRestorationService.restoreState()
        getNotificationsSettings()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let logger = logger
        Messaging.messaging().token { token, error in
            if let error = error {
                logger.error(
                    """
                    Error fetching Firebase Cloud Messaging registration token: \
                    \(error.localizedDescription, privacy: .public)
                    """
                )
                return
            }

            guard token != nil else {
                logger.error("Error: fetched an empty Firebase Cloud Messaging token.")
                return
            }

            logger.info("Successfully retrieved the Firebase Cloud Messaging token")
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("Failed to register for remote notifications: \(error.localizedDescription)")
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
        let authService = authService

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

        appState.$firebaseCloudMessagingToken.eraseToAnyPublisher()
            .combineLatest(
                appState.userState.$isAuthenticated.eraseToAnyPublisher(),
                appState.userState.$userProviderId.eraseToAnyPublisher(),
                appState.userState.$userId.eraseToAnyPublisher()
            )
            .sink { input in
                let (token, isAuthenticated, userProviderId, userId) = input
                guard isAuthenticated,
                      let token = token,
                      let userProviderId = userProviderId,
                      let userId = userId,
                      !userProviderId.isEmpty,
                      !userId.isEmpty
                else { return }

                Task.detached(priority: .utility) {
                    try await authService.saveFCMToken(
                        forUserWithId: userId,
                        userProviderId: userProviderId,
                        token: token
                    )
                }
            }
            .store(in: &cancellables)
        appState.userState.$isAuthenticated.eraseToAnyPublisher()
            .combineLatest(appState.userState.$reportStateChangeNotificationsEnabled.eraseToAnyPublisher())
            .debounce(for: 3, scheduler: DispatchQueue.global(qos: .userInitiated))
            .sink { input in
                let (isAuthenticated, reportStateChangeNotificationsEnabled) = input
                guard isAuthenticated else { return }
                Task {
                    try await authService.saveReportStatusChangeNotificationsPreference(
                        newValue: reportStateChangeNotificationsEnabled
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func getNotificationsSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    self?.appState.hasNotificationsPermissions = true
                default:
                    self?.appState.hasNotificationsPermissions = false
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    // TBD
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        appState.firebaseCloudMessagingToken = fcmToken
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
                .environmentObject(delegate.stateRestorationService)
        }
        .onChange(of: scenePhase) { newValue in
            if newValue == .background {
                try? delegate.stateRestorationService.saveState()
            }
        }
    }
}

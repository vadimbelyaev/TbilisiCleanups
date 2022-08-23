import Combine
import Firebase
import os.log
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    let appState: AppState = .init()
    private(set) lazy var userService = UserService(appState: appState)
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
        _ = userService

        setUpSubscriptions()
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        try? stateRestorationService.restoreState()
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

    // MARK: - Subscriptions

    private func setUpSubscriptions() {
        setUpReportFetchSubscription()
        setUpFCMTokenSaveSubscription()
        setUpNotificationPreferencesSubscription()
    }

    private func setUpReportFetchSubscription() {
        let reportService = self.reportService
        let appState = self.appState
        let userService = userService

        userService.userPublisher
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

    private func setUpFCMTokenSaveSubscription() {
        let userService = userService
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
                    try await userService.saveFCMToken(
                        forUserWithId: userId,
                        userProviderId: userProviderId,
                        token: token
                    )
                }
            }
            .store(in: &cancellables)
    }

    private func setUpNotificationPreferencesSubscription() {
        let appState = appState
        let userService = userService
        appState.userState.$isAuthenticated.eraseToAnyPublisher()
            .combineLatest(
                appState.userState
                    .updateReportNotificationsPreference
                    .eraseToAnyPublisher()
            )
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { input in
                appState.userState.reportNotificationsEnabled = input.1
            })
            .debounce(for: 3, scheduler: DispatchQueue.global(qos: .userInitiated))
            .sink { input in
                let (isAuthenticated, reportStateChangeNotificationsEnabled) = input
                guard isAuthenticated else { return }
                Task {
                    try await userService.saveReportStatusChangeNotificationsPreference(
                        newValue: reportStateChangeNotificationsEnabled
                    )
                }
            }
            .store(in: &cancellables)
    }

    func getNotificationsSettings() {
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
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let reportId = userInfo["report_id"] as? String else {
            return
        }
        appState.selectedTab = .userProfile
        appState.userProfileSelectedReportId = reportId
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let reportService = reportService
        Task.detached(priority: .userInitiated) {
            await withThrowingTaskGroup(of: Void.self, body: { group in
                group.addTask {
                    try await reportService.fetchReportsByCurrentUser()
                }
                group.addTask {
                    try await reportService.fetchVerifiedReports()
                }
            })
        }
        return [.badge, .banner]
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        appState.firebaseCloudMessagingToken = fcmToken
    }
}

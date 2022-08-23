import Combine
import Firebase
import FirebaseAuthUI
import FirebaseCrashlytics
import FirebaseEmailAuthUI
import FirebaseFacebookAuthUI
import FirebaseGoogleAuthUI
import FirebaseOAuthUI

@MainActor
final class UserService: NSObject, ObservableObject {
    private let appState: AppState

    private let userSubject: PassthroughSubject<Firebase.User?, Never> = .init()
    private(set) lazy var userPublisher = userSubject.eraseToAnyPublisher()

    init(appState: AppState) {
        self.appState = appState
        super.init()
        Auth.auth().addStateDidChangeListener { auth, user in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.userSubject.send(user)
                if let user = user,
                   !user.isAnonymous
                {
                    self.appState.userState.isAuthenticated = true
                    self.appState.userState.userId = user.providerData.first?.uid ?? "unknown"
                    self.appState.userState.userProviderId = user.providerData.first?.providerID ?? "unknown"
                    self.appState.userState.userName = user.displayName
                    if user.displayName == nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                            Auth.auth().currentUser?.reload()
                            self.appState.userState.userName = Auth.auth().currentUser?.displayName
                        }
                    }
                    Task.detached(priority: .userInitiated) { [weak self] in
                        guard let self = self else { return }
                        let allowed = try await self.readReportStatusChangeNotificationsPreference()
                        await MainActor.run {
                            appState.userState.reportStateChangeNotificationsEnabled = allowed
                        }
                    }
                } else {
                    self.appState.userState.isAuthenticated = false
                    self.appState.userState.userId = nil
                    self.appState.userState.userProviderId = nil
                    self.appState.userState.userName = nil
                }
            }
        }
    }

    private(set) lazy var authUI: FUIAuth = {
        guard let authUI = FUIAuth.defaultAuthUI() else {
            fatalError("Could not create Auth UI")
        }
        authUI.providers = [
            FUIEmailAuth()
//            FUIOAuth.appleAuthProvider(),
//            FUIGoogleAuth(authUI: authUI),
//            FUIFacebookAuth(authUI: authUI),
//            FUIOAuth.twitterAuthProvider()
        ]
        authUI.delegate = self
        return authUI
    }()

    func signOut() {
        do {
            try Auth.auth().signOut()
            appState.currentDraft = .init()
        } catch {
            Crashlytics.crashlytics().record(error: error)
        }
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser,
              let userId = appState.userState.userId,
              let providerId = appState.userState.userProviderId
        else {
            throw UserServiceError.notAuthenticated
        }
        // First, erase account data of the user's reports
        let firestore = Firestore.firestore()
        let references = try await firestore.collection("reports")
            .whereField("user_id", isEqualTo: userId)
            .whereField("user_provider_id", isEqualTo: providerId)
            .getDocuments()
            .documents
            .map(\.reference)
        let batch = firestore.batch()
        for reference in references {
            batch.updateData(["user_id": "__DELETED_USER__"], forDocument: reference)
            batch.updateData(["user_provider_id": "__DELETED_USER__"], forDocument: reference)
            batch.updateData(["user_name": "Deleted User"], forDocument: reference)
        }
        try await batch.commit()

        // Then delete the user's account
        do {
            try await user.delete()
        } catch {
            Crashlytics.crashlytics().record(error: error)
            throw error
        }
    }

    func saveFCMToken(forUserWithId userId: String, userProviderId: String, token: String) async throws {
        let document = try await fetchUserInfoSnapshot(forUserWithId: userId, userProviderId: userProviderId)
        var fcmTokens: [String] = {
            guard document.exists,
                  let data = document.data(),
                  let tokens = data["fcm_tokens"] as? [String]
            else { return [] }
            return tokens
        }()
        if !fcmTokens.contains(token) {
            fcmTokens.append(token)
        }
        let reference = makeUserInfoDocumentReference(forUserWithId: userId, userProviderId: userProviderId)
        try await reference.setData(
            [
                "fcm_tokens": fcmTokens,
                "last_used_locale": Locale.current.identifier
            ],
            merge: true
        )
    }

    func readReportStatusChangeNotificationsPreference() async throws -> Bool {
        guard let userId = appState.userState.userId,
              let userProviderId = appState.userState.userProviderId
        else {
            throw UserServiceError.notAuthenticated
        }
        let document = try await fetchUserInfoSnapshot(forUserWithId: userId, userProviderId: userProviderId)
        guard document.exists,
              let data = document.data(),
              let value = data["report_status_change_notifications_enabled"] as? Bool
        else {
            return false
        }
        return value
    }

    func saveReportStatusChangeNotificationsPreference(newValue: Bool) async throws {
        guard let userId = appState.userState.userId,
              let userProviderId = appState.userState.userProviderId
        else {
            throw UserServiceError.notAuthenticated
        }
        let reference = makeUserInfoDocumentReference(
            forUserWithId: userId,
            userProviderId: userProviderId
        )
        try await reference.setData(
            [
                "report_status_change_notifications_enabled": newValue,
                "last_used_locale": Locale.current.identifier
            ],
            merge: true
        )
    }

    private func makeUserInfoDocumentReference(
        forUserWithId userId: String,
        userProviderId: String
    ) -> DocumentReference {
        Firestore.firestore()
            .collection("user_providers")
            .document(userProviderId)
            .collection("users")
            .document(userId)
    }

    private func fetchUserInfoSnapshot(
        forUserWithId userId: String,
        userProviderId: String
    ) async throws -> DocumentSnapshot {
        let reference = makeUserInfoDocumentReference(forUserWithId: userId, userProviderId: userProviderId)
        return try await reference.getDocument()
    }
}

enum UserServiceError: Error {
    case notAuthenticated
}

extension UserService: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let error = error {
            Crashlytics.crashlytics().record(error: error)
            return
        }
        guard authDataResult != nil else { return }
        appState.userState.isAuthenticated = true
    }
}

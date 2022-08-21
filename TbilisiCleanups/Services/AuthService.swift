import Combine
import Firebase
import FirebaseAuthUI
import FirebaseCrashlytics
import FirebaseEmailAuthUI
import FirebaseFacebookAuthUI
import FirebaseGoogleAuthUI
import FirebaseOAuthUI

@MainActor
final class AuthService: NSObject, ObservableObject {
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
            throw AuthServiceError.notAuthenticated
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
}

enum AuthServiceError: Error {
    case notAuthenticated
}

extension AuthService: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        if let error = error {
            Crashlytics.crashlytics().record(error: error)
            return
        }
        guard authDataResult != nil else { return }
        appState.userState.isAuthenticated = true
    }
}

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

    func deleteAccount() {
        Auth.auth().currentUser?.delete { error in
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
            }
        }
    }
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

import Firebase
import FirebaseCrashlytics
import FirebaseEmailAuthUI
import FirebaseAuthUI
import FirebaseOAuthUI
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI
import Combine

@MainActor
final class AuthService: NSObject, ObservableObject {

    private let userState: UserState

    private let userSubject: PassthroughSubject<Firebase.User?, Never> = .init()
    private(set) lazy var userPublisher = userSubject.eraseToAnyPublisher()

    init(userState: UserState) {
        self.userState = userState
        super.init()
        Auth.auth().addStateDidChangeListener { auth, user in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.userSubject.send(user)
                if let user = user,
                   !user.isAnonymous
                {
                    self.userState.isAuthenticated = true
                    self.userState.userId = user.providerData.first?.uid ?? "unknown"
                    self.userState.userProviderId = user.providerData.first?.providerID ?? "unknown"
                    self.userState.userName = user.displayName
                } else {
                    self.userState.isAuthenticated = false
                    self.userState.userId = nil
                    self.userState.userProviderId = nil
                    self.userState.userName = nil
                }
            }
        }
    }

    private(set) lazy var authUI: FUIAuth = {
        guard let authUI = FUIAuth.defaultAuthUI() else {
            fatalError("Could not create Auth UI")
        }
        authUI.providers = [
            FUIEmailAuth(),
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
        userState.isAuthenticated = true
    }
}

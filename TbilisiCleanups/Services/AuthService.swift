import Firebase
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
        // TODO: Error handling
        try? Auth.auth().signOut()
    }

    func deleteAccount() {
        // TODO: Error handling
        Auth.auth().currentUser?.delete()
    }
}

extension AuthService: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        guard error == nil, authDataResult != nil else { return }
        userState.isAuthenticated = true
    }
}

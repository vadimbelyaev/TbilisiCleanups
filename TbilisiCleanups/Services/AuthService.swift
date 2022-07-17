import FirebaseEmailAuthUI
import FirebaseAuthUI
import FirebaseOAuthUI
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI

@MainActor
final class AuthService: NSObject, ObservableObject {

    private let userState: UserState

    init(userState: UserState) {
        self.userState = userState
        super.init()
        Auth.auth().addStateDidChangeListener { auth, user in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let user = user {
                    self.userState.isAuthenticated = true
                    self.userState.userName = user.displayName
                } else {
                    self.userState.isAuthenticated = false
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
}

extension AuthService: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        guard error == nil, authDataResult != nil else { return }
        userState.isAuthenticated = true
    }
}

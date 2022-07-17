import FirebaseEmailAuthUI
import FirebaseAuthUI
import FirebaseOAuthUI
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI

final class UserState: NSObject, ObservableObject {
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
    @Published var isAuthenticated: Bool = false
}

extension UserState: FUIAuthDelegate {
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        guard error == nil, authDataResult != nil else { return }
        isAuthenticated = true
    }
}

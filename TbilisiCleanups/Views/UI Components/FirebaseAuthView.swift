import SwiftUI

struct FirebaseAuthView: UIViewControllerRepresentable {

    @EnvironmentObject private var userState: UserState

    func makeUIViewController(context: Context) -> some UIViewController {
        userState.authUI.authViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // no-op
    }
}

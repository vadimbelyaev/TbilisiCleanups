import SwiftUI

struct FirebaseAuthView: UIViewControllerRepresentable {
    @EnvironmentObject private var userService: UserService

    func makeUIViewController(context: Context) -> some UIViewController {
        userService.authUI.authViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // no-op
    }
}

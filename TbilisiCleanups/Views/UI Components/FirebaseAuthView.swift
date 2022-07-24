import SwiftUI

struct FirebaseAuthView: UIViewControllerRepresentable {
    @EnvironmentObject private var authService: AuthService

    func makeUIViewController(context: Context) -> some UIViewController {
        authService.authUI.authViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // no-op
    }
}

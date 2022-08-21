import AVKit
import SwiftUI

struct AVPlayerRepresentable: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: url)
        controller.allowsPictureInPicturePlayback = true
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // no-op
    }
}

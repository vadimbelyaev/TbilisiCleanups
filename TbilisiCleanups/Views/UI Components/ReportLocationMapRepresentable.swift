import MapKit
import SwiftUI

struct ReportLocationMapRepresentable: UIViewControllerRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var location: CLLocationCoordinate2D
    let isInteractive: Bool

    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = ReportLocationMapViewController(
            initialRegion: region,
            initialLocation: location,
            isInteractive: isInteractive,
            regionDidChange: { region = $0 },
            locationDidChange: { location = $0 }
        )
        context.coordinator.managedController = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let mapViewController = uiViewController as? ReportLocationMapViewController else { return }
        mapViewController.region = region
        mapViewController.location = location
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}

extension ReportLocationMapRepresentable {
    final class Coordinator {
        var managedController: ReportLocationMapViewController?
    }
}

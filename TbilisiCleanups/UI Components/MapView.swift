import MapKit
import SwiftUI

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> some UIView {
        let view = MKMapView()
        view.showsUserLocation = true
        view.region = region
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let view = uiView as? MKMapView else { return }
        view.region = region
    }

    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator(managedView: self)
    }

    final class MapViewCoordinator: NSObject, MKMapViewDelegate {
        var managedView: MapView

        init(managedView: MapView) {
            self.managedView = managedView
            super.init()
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            managedView.region = mapView.region
        }
    }
}

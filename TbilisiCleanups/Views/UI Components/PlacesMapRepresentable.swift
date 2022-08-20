import MapKit
import SwiftUI

struct PlacesMapRepresentable: UIViewControllerRepresentable {
    let initialRegion: MKCoordinateRegion
    let places: [Report]
    let placeDetailsTapAction: (Report) -> Void

    func makeUIViewController(context: Context) -> some UIViewController {
        PlacesMapViewController(
            initialRegion: initialRegion,
            places: places,
            placeDetailsTapAction: placeDetailsTapAction
        )
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let placesMapViewController = uiViewController as? PlacesMapViewController else {
            return
        }
        placesMapViewController.places = places
    }
}

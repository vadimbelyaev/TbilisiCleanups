import MapKit
import SwiftUI

final class AppState: ObservableObject {
    @Published var currentDraft: ReportDraft = .empty
}

struct ReportDraft {
    var locationRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 37.334_900,
            longitude: -122.009_020
        ),
        latitudinalMeters: 750,
        longitudinalMeters: 750
    )
    var placeDescription: String
    var photos: [PlacePhoto]

    static let empty = ReportDraft(placeDescription: "", photos: [])
}

struct PlacePhoto: Identifiable {
    let id: String
    let itemProvider: NSItemProvider
}

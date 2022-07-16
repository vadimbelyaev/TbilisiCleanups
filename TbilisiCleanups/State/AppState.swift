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
    var medias: [PlaceMedia]

    static let empty = ReportDraft(placeDescription: "", medias: [])

    mutating func remove(media: PlaceMedia) {
        guard let index = medias.firstIndex(where: { $0.id == media.id }) else {
            return
        }
        medias.remove(at: index)
    }
}

struct PlaceMedia: Identifiable {
    let id: String
    let itemProvider: NSItemProvider
}

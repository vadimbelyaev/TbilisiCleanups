import MapKit
import SwiftUI

final class AppState: ObservableObject {
    var currentDraft: ReportDraft = .empty
}

class ReportDraft: ObservableObject {
    @Published var locationRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 37.334_900,
            longitude: -122.009_020
        ),
        latitudinalMeters: 750,
        longitudinalMeters: 750
    )
    @Published var placeDescription: String = ""
    @Published var medias: [PlaceMedia] = []

    static let empty = ReportDraft()

    func remove(media: PlaceMedia) {
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

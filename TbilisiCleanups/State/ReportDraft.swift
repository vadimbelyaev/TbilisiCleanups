import MapKit

@MainActor
class ReportDraft: ObservableObject {
    @Published var locationRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 42.182_724,
            longitude: 43.523_521
        ),
        latitudinalMeters: 600_000,
        longitudinalMeters: 600_000
    )
    @Published var placeDescription: String = ""
    @Published var medias: [PlaceMedia] = []
    @Published var submissionStatus: ReportSubmissionStatus = .notStarted

    func remove(media: PlaceMedia) {
        guard let index = medias.firstIndex(where: { $0.id == media.id }) else {
            return
        }
        medias.remove(at: index)
    }
}

struct PlaceMedia: Identifiable {
    let assetId: String
    let publicURL: URL?

    init(assetId: String, publicURL: URL? = nil) {
        self.assetId = assetId
        self.publicURL = publicURL
    }

    var id: String {
        assetId
    }
}

enum ReportSubmissionStatus {
    case notStarted
    case inProgress
    case failed(error: Error)
    case succeeded
}


import MapKit

struct ReportDraft: Identifiable {
    let id = UUID()
    var locationRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 42.182_724,
            longitude: 43.523_521
        ),
        latitudinalMeters: 600_000,
        longitudinalMeters: 600_000
    )
    var placeDescription: String = ""
    var medias: [PlaceMedia] = []

    mutating func remove(media: PlaceMedia) {
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

final class ReportSubmission: Identifiable, ObservableObject {
    let id = UUID()
    @Published var draft: ReportDraft

    init(draft: ReportDraft) {
        self.draft = draft
    }

    @Published var status: Status = .notStarted
}

extension ReportSubmission {
    enum Status {
        case notStarted
        case inProgress
        case failed(error: Error)
        case succeeded
    }
}

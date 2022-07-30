import MapKit

struct ReportDraft: Identifiable, Codable {
    var id: UUID
    var locationRegion: CodableLocationRegion = Self.defaultRegion
    var location: CodableLocation = Self.defaultLocation
    var placeDescription: String = ""
    var medias: [PlaceMedia] = []
    var uploadedMediasByType: UploadedMediasByType = .init(photos: [], videos: [])

    init() {
        id = UUID()
    }

    var isBlank: Bool {
        locationRegion == Self.defaultRegion
            && location == Self.defaultLocation
            && placeDescription.isEmpty
            && medias.isEmpty
            && uploadedMediasByType.photos.isEmpty
            && uploadedMediasByType.videos.isEmpty
    }

    var hasEmptyDescription: Bool {
        placeDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    mutating func remove(media: PlaceMedia) {
        guard let index = medias.firstIndex(where: { $0.id == media.id }) else {
            return
        }
        medias.remove(at: index)
    }

    static let defaultLocation = CodableLocation(
        clLocationCoordinate2D: CLLocationCoordinate2D(
            latitude: 42.182_724,
            longitude: 43.523_521
        )
    )

    static let defaultRegion = CodableLocationRegion(
        region: MKCoordinateRegion(
            center: defaultLocation.clLocationCoordinate2D,
            latitudinalMeters: 600_000,
            longitudinalMeters: 600_000
        )
    )
}

/// Codable equivalent of MKCoordinateRegion
struct CodableLocationRegion: Codable, Equatable {
    let centerLatitude: Double
    let centerLongitude: Double
    let spanLatitudeDelta: Double
    let spanLongitudeDelta: Double

    init(region: MKCoordinateRegion) {
        self.centerLatitude = region.center.latitude
        self.centerLongitude = region.center.longitude
        self.spanLatitudeDelta = region.span.latitudeDelta
        self.spanLongitudeDelta = region.span.longitudeDelta
    }

    var mkCoordinateRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: centerLatitude,
                longitude: centerLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: spanLatitudeDelta,
                longitudeDelta: spanLongitudeDelta
            )
        )
    }
}

/// Codable equivalent of CLLocationCoordinate2D
struct CodableLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    init(clLocationCoordinate2D: CLLocationCoordinate2D) {
        self.latitude = clLocationCoordinate2D.latitude
        self.longitude = clLocationCoordinate2D.longitude
    }

    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct PlaceMedia: Identifiable, Codable {
    let id: UUID
    let assetId: String

    init(assetId: String) {
        self.id = UUID()
        self.assetId = assetId
    }
}

struct UploadedMediasByType: Codable {
    let photos: [UploadedMedia]
    let videos: [UploadedMedia]
}

struct UploadedMedia: Identifiable, Codable {
    let id: String
    let assetId: String
    let url: URL
    let previewImageURL: URL
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
    enum Status: Equatable {
        case notStarted
        case inProgress
        case failed(error: Error)
        case succeeded

        static func == (lhs: ReportSubmission.Status, rhs: ReportSubmission.Status) -> Bool {
            switch (lhs, rhs) {
            case (.notStarted, .notStarted):
                return true
            case (.inProgress, .inProgress):
                return true
            case (.failed, .failed):
                return true
            case (.succeeded, .succeeded):
                return true
            default:
                return false
            }
        }
    }
}

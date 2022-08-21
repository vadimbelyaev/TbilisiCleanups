import CoreLocation
import Foundation

struct Report: Identifiable {
    let id: String
    let description: String?
    let createdOn: Date
    let photos: [Media]
    let videos: [Media]
    let status: Status
    let location: Location

    init(withFirestoreData data: [String: Any]) throws {
        guard let id = data["id"] as? String else {
            throw ParsingError.missingID
        }
        self.id = id

        guard let timestamp = data["created_on"] as? TimeInterval else {
            throw ParsingError.missingCreatedOn
        }
        self.createdOn = Date(timeIntervalSince1970: timestamp)

        self.description = data["description"] as? String

        if let photoCollection = data["photos"] as? [[String: String]] {
            self.photos = photoCollection
                .compactMap { Self.parseMedia(data: $0) }
        } else {
            self.photos = []
        }

        if let videoCollection = data["videos"] as? [[String: String]] {
            self.videos = videoCollection
                .compactMap { Self.parseMedia(data: $0) }
        } else {
            self.videos = []
        }

        if let statusString = data["status"] as? String,
           let status = Status(rawValue: statusString)
        {
            self.status = status
        } else {
            self.status = .unknown
        }

        if let location = data["location"] as? [String: Double],
           let lat = location["lat"],
           let lon = location["lon"]
        {
            self.location = .init(lat: lat, lon: lon)
        } else {
            throw ParsingError.missingOrInvalidLocation
        }
    }

    var mainPreviewImageURL: URL? {
        photos.first?.previewImageURL ?? videos.first?.previewImageURL
    }

    private static func parseMedia(data: [String: String]) -> Media? {
        guard let id = data["id"],
              let urlString = data["url"],
              let url = URL(string: urlString),
              let previewImageURLString = data["preview_image_url"],
              let previewImageURL = URL(string: previewImageURLString)
        else {
            AnalyticsService.logEvent(AppError.couldNotParseReportMediaFromFirebase(data: data))
            return nil
        }
        return Media(id: id, url: url, previewImageURL: previewImageURL)
    }
}

extension Report {
    struct Media: Identifiable {
        let id: String
        let url: URL
        let previewImageURL: URL
    }

    enum Status: String {
        case moderation
        case dirty
        case scheduled
        case clean
        case rejected
        case unknown
    }

    struct Location {
        let lat: Double
        let lon: Double

        var clLocationCoordinate2D: CLLocationCoordinate2D {
            .init(latitude: lat, longitude: lon)
        }
    }

    enum ParsingError: Error {
        case missingID
        case missingCreatedOn
        case missingOrInvalidLocation
    }
}

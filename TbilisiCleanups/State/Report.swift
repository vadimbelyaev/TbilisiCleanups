import Foundation

struct Report: Decodable, Identifiable {
    let id: String
    let description: String?
    let createdOn: Date
    let photos: [Media]
    let videos: [Media]

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
            // TODO: Send analytics error
            return nil
        }
        return Media(id: id, url: url, previewImageURL: previewImageURL)
    }
}

extension Report {
    struct Media: Decodable {
        let id: String
        let url: URL
        let previewImageURL: URL
    }

    enum ParsingError: Error {
        case missingID
        case missingCreatedOn
    }
}

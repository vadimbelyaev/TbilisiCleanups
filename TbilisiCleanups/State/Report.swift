import Foundation

struct Report: Identifiable {
    let id: String
    let description: String?
    let createdOn: Date

    init?(withFirestoreData data: [String: Any]) {
        guard let id = data["id"] as? String else {
            return nil
        }
        self.id = id

        guard let timestamp = data["created_on"] as? TimeInterval else {
            return nil
        }
        self.createdOn = Date(timeIntervalSince1970: timestamp)
        
        self.description = data["description"] as? String
    }
}

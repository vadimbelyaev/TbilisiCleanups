import Foundation

enum SotoAWSConfigHelper {

    static func getConfig() throws -> SotoAWSConfig {
        guard let url = Bundle.main.url(forResource: "SotoAWS", withExtension: "plist") else {
            throw ConfigLoadError.fileNotFoundInBundle
        }
        let data = try Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        let config = try decoder.decode(SotoAWSConfig.self, from: data)
        print(config)
        return config
    }
}

extension SotoAWSConfigHelper {
    enum ConfigLoadError: Error {
        case fileNotFoundInBundle
    }
}

struct SotoAWSConfig: Decodable {
    let accessKeyId: String
    let secretAccessKey: String

    enum CodingKeys: String, CodingKey {
        case accessKeyId = "ACCESS_KEY_ID"
        case secretAccessKey = "SECRET_ACCESS_KEY"
    }
}

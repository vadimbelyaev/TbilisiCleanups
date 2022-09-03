import FirebaseAnalytics

enum AnalyticsService {
    static func logEvent(_ event: FirebaseAnalyticsLoggable) {
        Analytics.logEvent(event.eventName, parameters: event.parameters)
    }
}

protocol FirebaseAnalyticsLoggable {
    var eventName: String { get }
    var parameters: [String: Any]? { get }
}

enum AppError: FirebaseAnalyticsLoggable {
    case couldNotParseReportMediaFromFirebase(data: [String: Any])
    case duplicateAttemptToSendReport
    case reportsWithDuplicateIDExist(reportID: String)
    case couldNotParseReport(rawObject: [String: Any])
    case noAssetIdentifierFromPhotoPicker
    case couldNotFetchThumbnail(innerError: Error)

    var eventName: String { "app_error" }

    var parameters: [String: Any]? {
        switch self {
        case let .couldNotParseReportMediaFromFirebase(data):
            return [
                "error_type": "couldNotParseReportMediaFromFirebase",
                "data": data
            ]
        case .duplicateAttemptToSendReport:
            return [
                "error_type": "duplicateAttemptToSendReport"
            ]
        case let .reportsWithDuplicateIDExist(reportID):
            return [
                "error_type": "reportsWithDuplicateIDExist",
                "report_id": reportID
            ]
        case let .couldNotParseReport(rawObject):
            return [
                "error_type": "couldNotParseReport",
                "raw_object": rawObject
            ]
        case .noAssetIdentifierFromPhotoPicker:
            return [
                "error_type": "noAssetIdentifierFromPhotoPicker"
            ]
        case let .couldNotFetchThumbnail(innerError):
            return [
                "error_type": "couldNotFetchThumbnail",
                "inner_error": String(describing: dump(innerError))
            ]
        }
    }
}

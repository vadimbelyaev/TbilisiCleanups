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
    case couldNotParseReportMediaFromFirebase(data: [String: String])
    case duplicateAttemptToSendReport
    case reportsWithDuplicateIDExist(reportID: String)

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
        }
    }
}

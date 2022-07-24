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

    var eventName: String {
        switch self {
        case .couldNotParseReportMediaFromFirebase:
            return "couldNotParseReportMediaFromFirebase"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .couldNotParseReportMediaFromFirebase(data):
            return data
        }
    }
}

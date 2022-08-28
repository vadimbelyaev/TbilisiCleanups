import Foundation

extension Report.Status {
    var localizedDescription: String {
        switch self {
        case .moderation:
            return L10n.ReportStatus.moderation
        case .dirty:
            return L10n.ReportStatus.dirty
        case .scheduled:
            return L10n.ReportStatus.scheduled
        case .clean:
            return L10n.ReportStatus.clean
        case .rejected:
            return L10n.ReportStatus.rejected
        case .unknown:
            return L10n.ReportStatus.unknown
        }
    }
}

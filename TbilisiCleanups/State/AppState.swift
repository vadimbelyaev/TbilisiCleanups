import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: MainTab = .reportStart
    @Published var isReportSheetPresented = false
    @Published var currentDraft: ReportDraft = .init()
    @Published var currentSubmission: ReportSubmission = .init(draft: .init())
    @Published var draftSubmissionQueue: [ReportSubmission] = []
    @Published var userReports: [Report] = []
    @Published var userReportsLoadingState: LoadingState = .notStarted
    @Published var verifiedReports: [Report] = []
    @Published var verifiedReportsLoadingState: LoadingState = .notStarted
    @Published var firebaseCloudMessagingToken: String?
    @Published var hasNotificationsPermissions: Bool = false
    @Published var userReportsScreenVisible: Bool = false
    @Published var userProfileSelectedReportId: String?
    var userState: UserState = .init()

    func dequeue(submission: ReportSubmission) {
        guard let index = draftSubmissionQueue.firstIndex(where: { $0.id == submission.id }) else {
            return
        }
        draftSubmissionQueue.remove(at: index)
    }
}

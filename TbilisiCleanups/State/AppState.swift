import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: MainTab = .reportStart
    @Published var isReportSheetPresented = false
    @Published var currentDraft: ReportDraft = .init()
    @Published var currentSubmission: ReportSubmission = .init(draft: .init())
    @Published var draftSubmissionQueue: [ReportSubmission] = []
    @Published var userReports: [Report] = []
    var userState: UserState = .init()

    func dequeue(submission: ReportSubmission) {
        guard let index = draftSubmissionQueue.firstIndex(where: { $0.id == submission.id }) else {
            return
        }
        draftSubmissionQueue.remove(at: index)
    }
}


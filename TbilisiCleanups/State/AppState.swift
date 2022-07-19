import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var currentDraft: ReportDraft = .init()
    @Published var currentSubmission: ReportSubmission = .init(draft: .init())
    @Published var draftSubmissionQueue: [ReportSubmission] = []
    var userState: UserState = .init()
}


import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var currentDraft: ReportDraft = .init()
    @Published var draftSubmissionQueue: [ReportDraft] = []
    var userState: UserState = .init()
}


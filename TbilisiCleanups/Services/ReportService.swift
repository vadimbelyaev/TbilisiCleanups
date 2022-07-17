import Foundation

final class ReportService: ObservableObject {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func submitCurrentDraft() async throws {

    }
}

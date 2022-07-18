import Foundation

final class ReportService: ObservableObject {
    private let appState: AppState
    private let mediaUploadService: MediaUploadService

    init(appState: AppState) {
        self.appState = appState
        self.mediaUploadService = MediaUploadService(appState: appState)
    }

    func submitCurrentDraft() async throws {
        let _ = try await mediaUploadService.uploadMedias(appState.currentDraft.medias)
    }
}

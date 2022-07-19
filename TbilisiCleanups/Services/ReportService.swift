import FirebaseFirestore
import Foundation

final class ReportService: ObservableObject {
    private let appState: AppState
    private let mediaUploadService: MediaUploadService

    init(appState: AppState) {
        self.appState = appState
        self.mediaUploadService = MediaUploadService(appState: appState)
    }

    func submitCurrentDraft() async throws {
        let draftToSubmit = await appState.currentDraft
        await MainActor.run {
            appState.draftSubmissionQueue.append(draftToSubmit)
            appState.currentDraft = ReportDraft()
        }
        let updatedMedias = try await mediaUploadService.uploadMedias(draftToSubmit.medias)
        await MainActor.run {
            draftToSubmit.medias = updatedMedias
        }
    }
}

private func saveReportToFirebase(_ draft: ReportDraft) async throws {

}

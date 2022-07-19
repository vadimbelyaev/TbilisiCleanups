import FirebaseFirestore
import Foundation

@MainActor
final class ReportService: ObservableObject {
    private let appState: AppState
    private let mediaUploadService: MediaUploadService

    init(appState: AppState) {
        self.appState = appState
        self.mediaUploadService = MediaUploadService()
    }

    func submitCurrentDraft() async throws {
        let submission = ReportSubmission(draft: appState.currentDraft)
        submission.status = .inProgress
        appState.currentSubmission = submission
        appState.draftSubmissionQueue.append(submission)
        appState.currentDraft = ReportDraft()

        do {
            let updatedMedias = try await mediaUploadService.uploadMedias(submission.draft.medias)
            await MainActor.run {
                submission.draft.medias = updatedMedias
            }
        } catch {
            try await MainActor.run {
                submission.status = .failed(error: error)
                // Trigger an extra objectWillChange because sometimes
                // just updating submission.status doesn't update the UI
                appState.currentSubmission = submission
                throw error
            }
        }
        
        submission.status = .succeeded
        // Trigger an extra objectWillChange because sometimes
        // just updating submission.status doesn't update the UI
        appState.currentSubmission = submission
        appState.dequeue(submission: submission)
        // TODO: Fetch from Firebase and then remove draft from the queue
    }
}

private func saveReportToFirebase(_ draft: ReportDraft) async throws {

}

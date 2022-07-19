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

        do {
            try await saveSubmissionToFirebase(submission, appState: appState)
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

private func saveSubmissionToFirebase(
    _ submission: ReportSubmission,
    appState: AppState
) async throws {
    let draft = submission.draft
    let reportData: [String: Any] = [
        "id": draft.id.uuidString,
        "reported_by": [
            "user_id": await appState.userState.userId ?? "N/A",
            "user_name": await appState.userState.userName ?? "N/A"
        ],
        "status": "moderation",
        "location": [
            "lat": draft.locationRegion.center.latitude,
            "lon": draft.locationRegion.center.longitude
        ],
        "photos": [],
        "videos": [],
        "cover": [],
        "description": draft.placeDescription
    ]

    let firestore = Firestore.firestore()
    try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
        firestore.collection("reports").addDocument(data: reportData) { error in
            if let error = error {
                continuation.resume(throwing: error)
                return
            }
            continuation.resume(returning: ())
        }
    })
}

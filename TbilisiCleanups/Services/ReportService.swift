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
            let uploadedMedias = try await mediaUploadService.uploadMedias(submission.draft.medias)
            await MainActor.run {
                submission.draft.uploadedMediasByType = uploadedMedias
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

        Task.detached(priority: .low) { [weak self] in
            guard let self = self else { return }
            try await fetchReports(appState: self.appState)
        }
    }

    func fetchReportsByCurrentUser() async throws {
        try await fetchReports(appState: appState)
    }
}

@MainActor
private func fetchReports(appState: AppState) async throws {
    guard appState.userState.isAuthenticated,
          let userId = appState.userState.userId,
          let providerId = appState.userState.userProviderId
    else {
        throw ReportServiceError.userUnauthenticated
    }

    let firestore = Firestore.firestore()
    let snapshot = try await firestore.collection("reports")
        .whereField("user_id", isEqualTo: userId)
        .whereField("user_provider_id", isEqualTo: providerId)
        .order(by: "created_on", descending: true)
        .getDocuments()
    let reports = snapshot
        .documents
        .map { $0.data() }
        .compactMap { Report(withFirestoreData: $0) }
    appState.userReports = reports
}

private func saveSubmissionToFirebase(
    _ submission: ReportSubmission,
    appState: AppState
) async throws {
    let draft = submission.draft
    let reportData: [String: Any] = [
        "id": draft.id.uuidString,
        "user_id": await appState.userState.userId ?? "",
        "user_provider_id": await appState.userState.userProviderId ?? "",
        "user_name": await appState.userState.userName ?? "",
        "created_on": Int(Date().timeIntervalSince1970),
        "status": "moderation",
        "location": [
            "lat": draft.locationRegion.center.latitude,
            "lon": draft.locationRegion.center.longitude
        ],
        "photos": draft.uploadedMediasByType.photos.map { $0.serializedForExport() },
        "videos": draft.uploadedMediasByType.videos.map { $0.serializedForExport() },
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

private extension UploadedMedia {
    func serializedForExport() -> [String: String] {
        [
            "id": id,
            "url": url.absoluteString,
            "preview_image_url": previewImageURL.absoluteString
        ]
    }
}

enum ReportServiceError: Error {
    case userUnauthenticated
}

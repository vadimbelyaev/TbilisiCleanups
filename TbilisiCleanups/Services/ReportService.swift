import FirebaseFirestore
import Foundation

@MainActor
final class ReportService: ObservableObject {
    private let appState: AppState
    private let mediaUploadService: MediaUploadService
    private let stateRestorationService: StateRestorationService

    init(appState: AppState) {
        self.appState = appState
        self.mediaUploadService = MediaUploadService()
        self.stateRestorationService = StateRestorationService(appState: appState)
    }

    func submitCurrentDraft() async throws {
        guard appState.currentSubmission.status != .inProgress else {
            AnalyticsService.logEvent(AppError.duplicateAttemptToSendReport)
            return
        }
        let submission = ReportSubmission(draft: appState.currentDraft)
        submission.status = .inProgress
        appState.currentSubmission = submission
        appState.draftSubmissionQueue.append(submission)

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
        appState.currentDraft = ReportDraft()
        stateRestorationService.eraseDraftState()

        Task.detached(priority: .low) { [weak self] in
            guard let self = self else { return }
            try await TbilisiCleanups.fetchReportsByCurrentUser(into: self.appState)
        }
    }

    func fetchReportsByCurrentUser() async throws {
        try await TbilisiCleanups.fetchReportsByCurrentUser(into: appState)
    }

    func fetchVerifiedReports() async throws {
        do {
            appState.verifiedReportsLoadingState = .loading

            let verifiedStatuses = [
                Report.Status.dirty,
                Report.Status.clean,
                Report.Status.scheduled
            ].map(\.rawValue)
            let firestore = Firestore.firestore()
            let snapshot = try await firestore.collection("reports")
                .whereField("status", in: verifiedStatuses)
                .order(by: "created_on", descending: true)
                .limit(to: 100)
                .getDocuments()
            let reports = snapshot
                .documents
                .map { $0.data() }
                .compactMap { rawObject -> Report? in
                    guard let report = try? Report(withFirestoreData: rawObject) else {
                        AnalyticsService.logEvent(AppError.couldNotParseReport(rawObject: rawObject))
                        return nil
                    }
                    return report
                }

            // Double check for duplicate IDs. Reports with duplicate IDs will
            // mess up the rendering and indicate report submission duplicates.
            var reportIDs: Set<String> = []
            var reportsWithUniqueIDs: [Report] = []
            for report in reports {
                if reportIDs.contains(report.id) {
                    AnalyticsService.logEvent(AppError.reportsWithDuplicateIDExist(reportID: report.id))
                } else {
                    reportIDs.insert(report.id)
                    reportsWithUniqueIDs.append(report)
                }
            }

            appState.verifiedReports = reportsWithUniqueIDs
            appState.verifiedReportsLoadingState = .loaded
        } catch {
            await MainActor.run {
                appState.verifiedReportsLoadingState = .failed
            }
            throw error
        }
    }
}

@MainActor
private func fetchReportsByCurrentUser(into appState: AppState) async throws {
    do {
        appState.userReportsLoadingState = .loading
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
            .compactMap { rawObject -> Report? in
                guard let report = try? Report(withFirestoreData: rawObject) else {
                    AnalyticsService.logEvent(AppError.couldNotParseReport(rawObject: rawObject))
                    return nil
                }
                return report
            }

        // Double check for duplicate IDs. Reports with duplicate IDs will
        // mess up the rendering and indicate report submission duplicates.
        var reportIDs: Set<String> = []
        var reportsWithUniqueIDs: [Report] = []
        for report in reports {
            if reportIDs.contains(report.id) {
                AnalyticsService.logEvent(AppError.reportsWithDuplicateIDExist(reportID: report.id))
            } else {
                reportIDs.insert(report.id)
                reportsWithUniqueIDs.append(report)
            }
        }

        appState.userReports = reportsWithUniqueIDs
        appState.userReportsLoadingState = .loaded
    } catch {
        await MainActor.run {
            appState.userReportsLoadingState = .failed
        }
        throw error
    }
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
            "lat": draft.location.latitude,
            "lon": draft.location.longitude
        ],
        "photos": draft.uploadedMediasByType.photos.map { $0.serializedForExport() },
        "videos": draft.uploadedMediasByType.videos.map { $0.serializedForExport() },
        "description": draft.placeDescription.trimmingCharacters(in: .whitespacesAndNewlines)
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

import FirebaseCrashlytics
import SwiftUI

struct ReportSubmissionView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var reportService: ReportService
    @State private var isFinished = false
    @Environment(\.dismiss) private var dismiss

    // Sometimes onAppear is called more than once, this flag
    // ensures we don't send the same report several times.
    @State private var hasAppeared = false

    var body: some View {
        statusView
            .navigationTitle("Submitting Report")
            .navigationBarBackButtonHidden(true)
            .onAppear {
                if !hasAppeared {
                    sendReport()
                }
                hasAppeared = true
            }
            .onChange(of: appState.currentSubmission.status) { newValue in
                if newValue == .succeeded {
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.success)
                } else if case .failed = newValue {
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(.error)
                }
            }
    }

    @ViewBuilder
    private var statusView: some View {
        switch appState.currentSubmission.status {
        case .notStarted:
            Text("Your report is about to be submitted.")
        case .inProgress:
            VStack(spacing: 24) {
                ProgressView()
                Text("Submitting your report...")
            }
            .padding(.horizontal)
        case .failed:
            VStack(spacing: 24) {
                Image(systemName: "xmark.octagon")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text("Error submitting the report. Please try again later.")
                    .lineLimit(0)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(.red)
                Button {
                    sendReport()
                } label: {
                    Text("Retry now")
                        .overlayNavigationLabelStyle()
                }
                .overlayNavigationLinkStyle()
            }
            .padding(.horizontal)
        case .succeeded:
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                Text("We received your report. Thank you!")
                    .lineLimit(0)
                    .foregroundColor(.green)
                Text("Check its status any time on the My Profile tab.")
                    .lineLimit(0)
                Button {
                    appState.isReportSheetPresented = false
                    appState.selectedTab = .userProfile
                } label: {
                    Text("Done")
                        .overlayNavigationLabelStyle()
                }
                .overlayNavigationLinkStyle()
            }
            .padding(.horizontal)
        }
    }

    private func sendReport() {
        Task.detached {
            do {
                try await reportService.submitCurrentDraft()
            } catch {
                Crashlytics.crashlytics().record(error: error)
                throw error
            }
            await MainActor.run {
                isFinished = true
            }
        }
    }
}

struct ReportSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        ReportSubmissionView()
    }
}

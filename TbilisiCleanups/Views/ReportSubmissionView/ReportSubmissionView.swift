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
                .fixedSize(horizontal: false, vertical: true)
        case .inProgress:
            VStack(spacing: 24) {
                ProgressView()
                Text("Submitting your report...")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
        case .failed:
            VStack(spacing: 24) {
                Image(systemName: "xmark.octagon")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text("Error submitting the report. Please try again later.")
                    .fixedSize(horizontal: false, vertical: true)
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
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.green)
                Text("Check its status any time on the My Profile tab.")
                    .fixedSize(horizontal: false, vertical: true)
                notificationView
                    .padding(.vertical, 32)
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

    @ViewBuilder
    private var notificationView: some View {
        if appState.hasNotificationsPermissions {
            if appState.userState.reportStateChangeNotificationsEnabled {
                Text("You'll receive a notification when the status of your report changes.")
            } else {
                Button {
                    appState.userState.updateReportStateChangeNotificationsPreference.send(true)
                } label: {
                    Text("Notify me when the status of the report changes")
                }
            }
        } else {
            Button {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    switch settings.authorizationStatus {
                    case .authorized:
                        assertionFailure("This case should be handled in the if branch above")
                    case .denied:
                        DispatchQueue.main.async {
                            guard let url = URL(string: UIApplication.openSettingsURLString),
                                  UIApplication.shared.canOpenURL(url)
                            else { return }
                            UIApplication.shared.open(url)
                        }
                    case .provisional, .ephemeral, .notDetermined:
                        UNUserNotificationCenter
                            .current()
                            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                                DispatchQueue.main.async {
                                    appState.hasNotificationsPermissions = granted
                                    if granted {
                                        appState.userState.updateReportStateChangeNotificationsPreference.send(true)
                                    }
                                }
                            }
                    @unknown default:
                        assertionFailure()
                    }
                }
            } label: {
                Text("Allow notifications to be informed of your report's status changes")
            }
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

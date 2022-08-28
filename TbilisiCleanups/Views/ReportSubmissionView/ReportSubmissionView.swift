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
            .navigationTitle(L10n.ReportSubmission.title)
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
            Text(L10n.ReportSubmission.Status.notStarted)
                .fixedSize(horizontal: false, vertical: true)
        case .inProgress:
            VStack(spacing: 24) {
                ProgressView()
                Text(L10n.ReportSubmission.Status.inProgress)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
        case .failed:
            VStack(spacing: 24) {
                Image(systemName: "xmark.octagon")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text(L10n.ReportSubmission.Status.failed)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.red)
                Button {
                    sendReport()
                } label: {
                    Text(L10n.ReportSubmission.retryNowButton)
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
                Text(L10n.ReportSubmission.Status.succeeded)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.green)
                Text(L10n.ReportSubmission.successNote)
                    .fixedSize(horizontal: false, vertical: true)
                notificationView
                    .padding(.vertical, 32)
                Button {
                    appState.isReportSheetPresented = false
                    appState.selectedTab = .userProfile
                    appState.userReportsScreenVisible = true
                } label: {
                    Text(L10n.Navigation.done)
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
            if appState.userState.reportNotificationsEnabled {
                Text(L10n.ReportSubmission.Notifications.youWillReceiveNotification)
            } else {
                Button {
                    appState.userState.updateReportNotificationsPreference.send(true)
                } label: {
                    Text(L10n.ReportSubmission.Notifications.notifyMeButton)
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
                                        appState.userState.updateReportNotificationsPreference.send(true)
                                    }
                                }
                            }
                    @unknown default:
                        assertionFailure()
                    }
                }
            } label: {
                Text(L10n.ReportSubmission.Notifications.allowNotificationsButton)
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

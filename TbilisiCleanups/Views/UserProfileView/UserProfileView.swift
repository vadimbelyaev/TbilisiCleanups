import NukeUI
import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var userState: UserState
    @EnvironmentObject private var userService: UserService
    @EnvironmentObject private var reportService: ReportService

    @State private var deleteAccountConfirmationPresented = false
    @State private var signInScreenPresented = false
    @State private var deleteAccountFailed = false

    var body: some View {
        NavigationView {
            if userState.isAuthenticated {
                signedInBody
            } else {
                guestBody
            }
        }
        .navigationViewStyle(.stack)
        .tabItem {
            Image(systemName: "person")
            Text("My Profile")
        }
    }

    @ViewBuilder
    private var signedInBody: some View {
        List {
            Section("My Reports") {
                if appState.userReportsLoadingState == .loading {
                    Text("Loading...")
                }
                if appState.userReportsLoadingState == .loaded,
                   appState.userReports.isEmpty
                {
                    Text("You haven't submitted any reports of littered places yet.")
                    Button {
                        appState.selectedTab = .reportStart
                    } label: {
                        Text("Submit a report")
                    }
                    .buttonStyle(.borderless)
                }
                if appState.userReportsLoadingState == .failed {
                    Label {
                        Text("Error loading your reports.")
                    } icon: {
                        Image(systemName: "exclamationmark.octagon")
                            .foregroundColor(.red)
                    }

                    Button {
                        Task.detached(priority: .low) {
                            try await reportService.fetchReportsByCurrentUser()
                        }
                    } label: {
                        Text("Retry")
                    }
                    .buttonStyle(.borderless)
                }
                ForEach(appState.userReports) { report in
                    reportCell(for: report)
                }
            }
            .listSectionSeparator(.hidden)
            Section("Notifications") {
                if appState.hasNotificationsPermissions {
                    Toggle("My reports status changes", isOn: $appState.userState.reportStateChangeNotificationsEnabled)
                } else {
                    allowNotificationsButton
                }
            }

            Section("Account") {
                Button("Sign out") {
                    userService.signOut()
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    deleteAccountConfirmationPresented = true
                } label: {
                    Text("Delete my account")
                }
                .confirmationDialog(
                    "Delete your account? This action cannot be undone.",
                    isPresented: $deleteAccountConfirmationPresented,
                    actions: deleteAccountConfirmationActions
                )
                .alert(
                    "There was an error deleting your account. Please try again later.",
                    isPresented: $deleteAccountFailed,
                    actions: {}
                )
            }
        }
        .refreshable {
            try? await reportService.fetchReportsByCurrentUser()
        }
        .listStyle(.inset)
        .navigationTitle(userState.userName ?? "Welcome")
    }

    @ViewBuilder
    private func deleteAccountConfirmationActions() -> some View {
        Button(role: .destructive) {
            Task {
                do {
                    try await userService.deleteAccount()
                } catch {
                    deleteAccountFailed = true
                }
            }
        } label: {
            Text("Delete my account")
        }
        Button(role: .cancel) {
            // no-op
        } label: {
            Text("Do not delete")
        }
    }

    @ViewBuilder
    private var guestBody: some View {
        List {
            Text("Manage your account, see your reports and their statuses.")
            Button {
                signInScreenPresented = true
            } label: {
                Text("Sign in")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sign In")
        .sheet(isPresented: $signInScreenPresented) {
            FirebaseAuthView()
                .ignoresSafeArea(.all, edges: .bottom)
        }
    }

    private func reportCell(for report: Report) -> some View {
        NavigationLink {
            ReportDetailsView(report: report)
        } label: {
            LazyImage(url: report.mainPreviewImageURL)
                .ignoresSafeArea(.container)
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .overlay(
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.description ?? "No description")
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .font(.title3)
                            .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Material.thickMaterial)
                        Spacer()
                        HStack {
                            Text(formatted(report.createdOn))
                                .font(.footnote)
                                .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                                .background(Material.thickMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            Spacer()
                            ReportStatusBadge(status: report.status)
                        }
                        .padding(4)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.top, 4)
        .listRowSeparator(.hidden)
    }

    private static let dateFormatter = RelativeDateTimeFormatter()

    private func formatted(_ date: Date) -> String {
        Self.dateFormatter.localizedString(for: date, relativeTo: .now)
    }

    private var allowNotificationsButton: some View {
        Button {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .authorized:
                    break
                case .denied:
                    if let url = URL(string: UIApplication.openSettingsURLString),
                       UIApplication.shared.canOpenURL(url)
                    {
                        UIApplication.shared.open(url)
                    }
                case .ephemeral, .notDetermined, .provisional:
                    Task {
                        let granted = try await UNUserNotificationCenter
                            .current()
                            .requestAuthorization(options: [.alert, .sound])
                        appState.hasNotificationsPermissions = granted
                    }
                @unknown default:
                    assertionFailure()
                }
            }
        } label: {
            Text("Allow notifications")
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}

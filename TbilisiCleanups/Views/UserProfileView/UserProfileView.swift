import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var userState: UserState
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var reportService: ReportService

    @State private var deleteAccountConfirmationPresented = false
    @State private var signInScreenPresented = false

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
            Section("Account") {
                Button("Sign out") {
                    authService.signOut()
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
            authService.deleteAccount()
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
        ZStack(alignment: .topLeading) {
            AsyncImage(url: report.mainPreviewImageURL) { image in
                image
                    .resizable()
                    .ignoresSafeArea(.container)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
            } placeholder: {
                Color.secondary.opacity(0.1)
                    .frame(height: 200)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: .zero) {
                Text(report.description ?? "No description")
                    .lineLimit(1)
                    .font(.title)
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.white.opacity(0.9).blur(radius: 4))
                Text(formatted(report.createdOn))
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.white.opacity(0.9).blur(radius: 2))
                Spacer()
                HStack {
                    Spacer()
                    ReportStatusBadge(status: report.status)
                }
            }
            .padding()
        }
        .listRowSeparator(.hidden)
    }

    private static let dateFormatter = RelativeDateTimeFormatter()

    private func formatted(_ date: Date) -> String {
        Self.dateFormatter.localizedString(for: date, relativeTo: .now)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}

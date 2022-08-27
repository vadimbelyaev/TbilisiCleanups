import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var userState: UserState
    @EnvironmentObject private var userService: UserService

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
                NavigationLink {
                    UserReportsView()
                } label: {
                    Text("My reports")
                }
            }
            Section("Notifications") {
                if appState.hasNotificationsPermissions {
                    Toggle("My reports status changes", isOn: makeReportNotificationsBinding())
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
        .listStyle(.insetGrouped)
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

    private func makeReportNotificationsBinding() -> Binding<Bool> {
        Binding(
            get: {
                appState.userState.reportNotificationsEnabled
            },
            set: { newValue in
                appState.userState.updateReportNotificationsPreference.send(newValue)
            }
        )
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}

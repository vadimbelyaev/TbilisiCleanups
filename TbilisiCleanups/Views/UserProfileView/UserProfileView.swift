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
            Text(L10n.UserProfile.tabName)
        }
    }

    @ViewBuilder
    private var signedInBody: some View {
        List {
            Section(L10n.UserProfile.contributionsSection) {
                NavigationLink(isActive: $appState.userReportsScreenVisible) {
                    UserReportsView()
                } label: {
                    Text(L10n.UserProfile.myReports)
                }
            }
            Section(L10n.UserProfile.notificationsSection) {
                if appState.hasNotificationsPermissions {
                    Toggle(L10n.UserProfile.statusesOfMyReports, isOn: makeReportNotificationsBinding())
                } else {
                    allowNotificationsButton
                }
            }

            Section(L10n.UserProfile.accountSection) {
                Button(L10n.UserProfile.signOutButton) {
                    userService.signOut()
                }
                .buttonStyle(.borderless)

                Button(role: .destructive) {
                    deleteAccountConfirmationPresented = true
                } label: {
                    Text(L10n.UserProfile.deleteMyAccount)
                }
                .confirmationDialog(
                    L10n.UserProfile.DeleteAccountConfirmation.title,
                    isPresented: $deleteAccountConfirmationPresented,
                    actions: deleteAccountConfirmationActions
                )
                .alert(
                    L10n.UserProfile.errorDeletingAccount,
                    isPresented: $deleteAccountFailed,
                    actions: {}
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(userState.userName ?? L10n.UserProfile.nonameTitle)
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
            Text(L10n.UserProfile.DeleteAccountConfirmation.deleteAction)
        }
        Button(role: .cancel) {
            // no-op
        } label: {
            Text(L10n.UserProfile.DeleteAccountConfirmation.doNotDeleteAction)
        }
    }

    @ViewBuilder
    private var guestBody: some View {
        List {
            Text(L10n.UserProfile.Guest.body)
            Button {
                signInScreenPresented = true
            } label: {
                Text(L10n.UserProfile.Guest.signInButton)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.UserProfile.Guest.title)
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
            Text(L10n.UserProfile.allowNotifications)
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

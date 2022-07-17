//
//  UserProfileView.swift
//  TbilisiCleanups
//
//  Created by Vadim Belyaev on 17.07.2022.
//

import SwiftUI

struct UserProfileView: View {

    @EnvironmentObject private var userState: UserState
    @EnvironmentObject private var authService: AuthService

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
    }

    @ViewBuilder
    private var signedInBody: some View {
        List {
            Button {
                authService.signOut()
            } label: {
                Text("Sign out")
            }

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
        .listStyle(.insetGrouped)
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
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}

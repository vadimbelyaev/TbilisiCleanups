import SwiftUI

struct ReportStartView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var userState: UserState
    @EnvironmentObject private var stateRestorationService: StateRestorationService
    @State private var isDiscardDraftDialogPresented = false
    @State private var signInScreenPresented = false

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    bodyText
                        .padding()
                }
                Spacer()
                buttons
            }
            .navigationTitle(L10n.ReportStart.title)
        }
        .sheet(isPresented: $appState.isReportSheetPresented) {
            NavigationView {
                ReportPhotosView()
            }
        }
        .sheet(isPresented: $signInScreenPresented) {
            FirebaseAuthView()
                .ignoresSafeArea(.all, edges: .bottom)
        }
        .confirmationDialog(
            L10n.ReportStart.DiscardDraftConfirmation.title,
            isPresented: $isDiscardDraftDialogPresented,
            titleVisibility: .visible,
            actions: {
                Button(
                    L10n.ReportStart.DiscardDraftConfirmation.startNewReportAction,
                    role: .destructive
                ) {
                    appState.currentDraft = .init()
                    stateRestorationService.eraseDraftState()
                    appState.isReportSheetPresented = true
                }
            }
        )
        .navigationViewStyle(.stack)
        .tabItem {
            Image(systemName: "square.and.pencil")
            Text(L10n.ReportStart.tabName)
        }
    }

    private var bodyText: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(L10n.ReportStart.bodyHeader)
                .font(.title)
                .padding(.bottom, 24)
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .frame(minWidth: 40)
                Text(L10n.ReportStart.bodyStep1)
            }
            .font(.title3)
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .frame(minWidth: 40)
                Text(L10n.ReportStart.bodyStep2)
            }
            .font(.title3)
            HStack {
                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    .frame(minWidth: 40)
                Text(L10n.ReportStart.bodyStep3)
            }
            .font(.title3)

            Text(L10n.ReportStart.bodyFinal)
                .padding(.top, 24)

            Text(L10n.ReportStart.bodyThankYou)
        }
    }

    private var buttons: some View {
        VStack {
            if !appState.currentDraft.isBlank {
                HStack {
                    Spacer()
                    Button {
                        isDiscardDraftDialogPresented = true
                    } label: {
                        Text(L10n.ReportStart.discardDraftButton)
                            .overlayNavigationLabelStyle()
                    }
                    .overlayNavigationLinkStyle()
                    .tint(.red)
                    Spacer()
                }
            }
            HStack {
                Spacer()
                if userState.isAuthenticated {
                    Button {
                        appState.isReportSheetPresented = true
                    } label: {
                        Text(
                            appState.currentDraft.isBlank
                                ? L10n.ReportStart.startButton
                                : L10n.ReportStart.continueDraftButton
                        )
                        .overlayNavigationLabelStyle()
                    }
                    .overlayNavigationLinkStyle()
                } else {
                    Button {
                        signInScreenPresented = true
                    } label: {
                        Text(L10n.ReportStart.signInButton)
                            .overlayNavigationLabelStyle()
                    }
                    .overlayNavigationLinkStyle()
                }
                Spacer()
            }
        }
        .animation(.easeInOut, value: userState.isAuthenticated)
        .padding(.bottom, 24)
    }
}

struct ReportStartView_Previews: PreviewProvider {
    static var previews: some View {
        ReportStartView()
    }
}

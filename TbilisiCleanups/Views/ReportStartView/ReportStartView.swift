import SwiftUI

struct ReportStartView: View {

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var userState: UserState
    @State private var reportScreenPresented = false
    @State private var signInScreenPresented = false

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    bodyText
                }
                Spacer()

                HStack {
                    Spacer()
                    if userState.isAuthenticated {
                        Button {
                            reportScreenPresented = true
                        } label: {
                            Text("Start")
                                .frame(maxWidth: 300)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            signInScreenPresented = true
                        } label: {
                            Text("Sign in to submit a report")
                                .frame(maxWidth: 300)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
                .animation(.easeInOut, value: userState.isAuthenticated)
                .padding(.bottom, 24)
            }
            .padding()
            .navigationTitle("New Report")
        }
        .sheet(isPresented: $reportScreenPresented) {
            NavigationView {
                ReportPhotosView(currentDraft: appState.currentDraft)
            }
        }
        .sheet(isPresented: $signInScreenPresented) {
            FirebaseAuthView()
        }
        .navigationViewStyle(.stack)
        .tabItem {
            Image(systemName: "square.and.pencil")
            Text("New Report")
        }
    }

    private var bodyText: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Report a littered place in 3 steps:")
                .font(.title)
                .padding(.bottom, 24)
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .frame(minWidth: 40)
                Text("Choose some photos or videos")
            }
            .font(.title3)
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .frame(minWidth: 40)
                Text("Tell us the location")
            }
            .font(.title3)
            HStack {
                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                    .frame(minWidth: 40)
                Text("Add a text description")
            }
            .font(.title3)

            Text("Once submitted, your report will be reviewed by our moderators.")
                .padding(.top, 24)

            Text("Thank you for contributing to a cleaner country!")
        }
    }
}

struct ReportStartView_Previews: PreviewProvider {
    static var previews: some View {
        ReportStartView()
    }
}

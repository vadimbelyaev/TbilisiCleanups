import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            ReportStartView()
                .tag(MainTab.reportStart)
            UserProfileView()
            .tabItem {
                Image(systemName: "person")
                Text("My Profile")
            }
            .tag(MainTab.userProfile)

            NavigationView {
                Text("About")
                    .navigationTitle("About")
            }
            .tabItem {
                Image(systemName: "info")
                Text("About")
            }
            .tag(MainTab.about)
        }
    }
}

enum MainTab {
    case reportStart
    case userProfile
    case about
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}

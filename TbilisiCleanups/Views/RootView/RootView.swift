import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: makeSelectedTabBinding()) {
            ReportStartView()
                .tag(MainTab.reportStart)
            PlacesMapView()
                .tag(MainTab.placesMap)
            UserProfileView()
                .tag(MainTab.userProfile)
            AboutView()
                .tag(MainTab.about)
        }
    }

    private func makeSelectedTabBinding() -> Binding<MainTab> {
        Binding(
            get: {
                appState.selectedTab
            },
            set: { newValue in
                if appState.selectedTab == newValue {
                    // Pop navigation stack of the tab to root
                    switch appState.selectedTab {
                    case .reportStart:
                        break
                    case .placesMap:
                        appState.placesMapSelectedReportId = nil
                    case .userProfile:
                        appState.userReportsScreenVisible = false
                        appState.userProfileSelectedReportId = nil
                    case .about:
                        break
                    }
                }
                appState.selectedTab = newValue
            }
        )
    }
}

enum MainTab {
    case reportStart
    case placesMap
    case userProfile
    case about
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}

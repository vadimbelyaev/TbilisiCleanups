import SwiftUI

struct RootView: View {

    @Binding var appState: AppState

    var body: some View {
        TabView {
            ReportStartView(appState: $appState)
            
            NavigationView {
                Text("My Reports")
                    .navigationTitle("My Reports")
            }
            .tabItem {
                Image(systemName: "scroll")
                Text("My Reports")
            }

            NavigationView {
                Text("About")
                    .navigationTitle("About")
            }
            .tabItem {
                Image(systemName: "info")
                Text("About")
            }

        }
    }
}

struct RootView_Previews: PreviewProvider {
    @State static var appState = AppState()
    static var previews: some View {
        RootView(appState: $appState)
    }
}

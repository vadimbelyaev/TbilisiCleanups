import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ReportStartView()
            UserProfileView()
            .tabItem {
                Image(systemName: "person")
                Text("My Profile")
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
    static var previews: some View {
        RootView()
    }
}

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ReportStartView()
            
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
    static var previews: some View {
        RootView()
    }
}

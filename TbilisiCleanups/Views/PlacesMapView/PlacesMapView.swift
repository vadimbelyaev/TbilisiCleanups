import MapKit
import SwiftUI

struct PlacesMapView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var reportService: ReportService
    var body: some View {
        NavigationView {
            ZStack {
                PlacesMapRepresentable(
                    initialRegion: ReportDraft.defaultRegion.mkCoordinateRegion,
                    places: appState.verifiedReports,
                    placeDetailsTapAction: { appState.placesMapSelectedReportId = $0.id }
                )
                Color.clear
                    .frame(width: .zero, height: .zero)
                    .hidden()
                    .background(
                        VStack {
                            ForEach(appState.verifiedReports) { report in
                                NavigationLink("", tag: report.id, selection: $appState.placesMapSelectedReportId) {
                                    ReportDetailsView(report: report)
                                }
                            }
                        }
                    )
            }
            .ignoresSafeArea(.all, edges: [.top, .horizontal])
            .onAppear {
                if appState.verifiedReports.isEmpty, appState.verifiedReportsLoadingState != .loaded {
                    Task.detached(priority: .userInitiated) {
                        try await reportService.fetchVerifiedReports()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .tabItem {
            Image(systemName: "map")
            Text(L10n.PlacesMap.tabName)
        }
    }
}

struct PlacesMapView_Previews: PreviewProvider {
    static var previews: some View {
        PlacesMapView()
    }
}

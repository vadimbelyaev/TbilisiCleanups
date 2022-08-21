import MapKit
import SwiftUI

struct PlacesMapView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var reportService: ReportService
    @State private var selectedReportId: String?
    var body: some View {
        NavigationView {
            ZStack {
                PlacesMapRepresentable(
                    initialRegion: ReportDraft.defaultRegion.mkCoordinateRegion,
                    places: appState.verifiedReports,
                    placeDetailsTapAction: { selectedReportId = $0.id }
                )
                Color.clear
                    .frame(width: .zero, height: .zero)
                    .hidden()
                    .background(
                        VStack {
                            ForEach(appState.verifiedReports) { report in
                                NavigationLink("", tag: report.id, selection: $selectedReportId) {
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
        .tabItem {
            Image(systemName: "map")
            Text("Places")
        }
    }
}

struct PlacesMapView_Previews: PreviewProvider {
    static var previews: some View {
        PlacesMapView()
    }
}

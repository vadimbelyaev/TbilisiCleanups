import CoreLocation
import CoreLocationUI
import MapKit
import SwiftUI

struct ReportLocationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var model = ReportLocationViewModel()

    var body: some View {
        ZStack {
            map
            OverlayNavigationLink(title: L10n.ReportLocation.useThisLocationButton) {
                ReportDescriptionView()
            } auxiliaryView: {
                locationButton
                    .padding(25)
            }
        }
        .navigationTitle(L10n.ReportLocation.title)
        .onChange(of: model.region) { newValue in
            appState.currentDraft.locationRegion = .init(region: newValue)
        }
        .onChange(of: model.location, perform: { newValue in
            appState.currentDraft.location = .init(clLocationCoordinate2D: newValue)
        })
        .onAppear {
            model.region = appState.currentDraft.locationRegion.mkCoordinateRegion
            model.location = appState.currentDraft.location.clLocationCoordinate2D
            model.setUpBindings(appState: appState)
        }
    }

    private var map: some View {
        ReportLocationMapRepresentable(
            region: $model.region,
            location: $model.location,
            isInteractive: true
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var locationButton: some View {
        switch model.locationButtonState {
        case .idle, .authorizationDenied:
            Button {
                model.requestLocation()
            } label: {
                if model.locationButtonState == .authorizationDenied {
                    Label(
                        L10n.ReportLocation.allowLocationAccessButton,
                        systemImage: "location.slash"
                    )
                    .labelStyle(.iconOnly)
                } else {
                    Label(
                        L10n.ReportLocation.showCurrentLocationButton,
                        systemImage: "location.fill"
                    )
                    .labelStyle(.iconOnly)
                }
            }
            .foregroundColor(.white)
            .frame(width: 50, height: 50)
            .background(Color.blue)
            .cornerRadius(25)
            .locationSettingsAlert(isPresented: $model.locationSettingsAlertPresented)
        case .inProgress:
            ProgressView()
                .frame(width: 50, height: 50)
        }
    }
}

private extension View {
    func locationSettingsAlert(isPresented: Binding<Bool>) -> some View {
        alert(
            L10n.ReportLocation.AccessAlert.title,
            isPresented: isPresented,
            actions: {
                Button(role: .cancel) {
                    // no-op
                } label: {
                    Text(L10n.ReportLocation.AccessAlert.notNowAction)
                }
                Button {
                    UIApplication.goToSettings()
                } label: {
                    Text(L10n.ReportLocation.AccessAlert.settingsAction)
                }
            }
        )
    }
}

struct ReportLocationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportLocationView()
        }
    }
}

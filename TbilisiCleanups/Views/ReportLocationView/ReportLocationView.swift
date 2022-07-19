import CoreLocation
import CoreLocationUI
import MapKit
import SwiftUI

struct ReportLocationView: View {

    @ObservedObject var currentDraft: ReportDraft
    @StateObject private var model = ReportLocationViewModel()

    var body: some View {
        ZStack {
            map
            OverlayNavigationLink(title: "Use this location") {
                ReportDescriptionView(currentDraft: currentDraft)
            } auxiliaryView: {
                locationButton
                    .padding(25)

            }
        }
        .navigationTitle("Location")
        .onAppear {
            model.setUpBindings(currentDraft: currentDraft)
        }
    }

    private var map: some View {
        MapView(
            region: $currentDraft.locationRegion
        )
            .ignoresSafeArea(
                .all,
                edges: [.leading, .trailing, .top]
            )
            .overlay(
                Image(systemName: "mappin")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .alignmentGuide(VerticalAlignment.center, computeValue: { d in
                        d[.bottom]
                    })
            )
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
                        "Allow access to location",
                        systemImage: "location.slash"
                    )
                    .labelStyle(.iconOnly)
                } else {
                    Label(
                        "Show current location",
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

    private var continueButton: some View {
        NavigationLink {
            ReportDescriptionView(currentDraft: currentDraft)
        } label: {
            Text("Use this location")
                .frame(maxWidth: 300)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom, 25)
    }
}

private extension View {
    func locationSettingsAlert(isPresented: Binding<Bool>) -> some View {
        alert(
            "Please allow access to location in the Settings app.",
            isPresented: isPresented,
            actions: {
                Button(role: .cancel) {
                    // no-op
                } label: {
                    Text("Not now")
                }
                Button {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                          UIApplication.shared.canOpenURL(settingsUrl)
                    else { return }
                    UIApplication.shared.open(settingsUrl)
                } label: {
                    Text("Settings")
                }
            }
        )
    }
}

struct ReportLocationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportLocationView(currentDraft: .init())
        }
    }
}

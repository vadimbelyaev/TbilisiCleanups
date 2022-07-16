import CoreLocation
import CoreLocationUI
import MapKit
import SwiftUI

struct ReportLocationView: View {

    @EnvironmentObject var currentDraft: ReportDraft
    @StateObject private var model = ReportLocationViewModel()

    var body: some View {
        ZStack {
            map
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    locationButton
                        .padding(25)
                }
                HStack {
                    Spacer()
                    continueButton
                    Spacer()
                }
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
                Label("Show current location", systemImage: model.locationButtonState == .authorizationDenied ? "location.slash" : "location.fill")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderedProminent)
            .cornerRadius(25)
            .alert(
                "Enable ins setgings",
                isPresented: $model.locationSettingsAlertPresented,
                actions: {
                    Button("NotNow") {}
                    Button("Settings") {}
                }
            )
        case .inProgress:
            ProgressView()
        case .restricted:
            EmptyView()
        }
    }

    private var continueButton: some View {
        NavigationLink {
            ReportDescriptionView()
        } label: {
            Text("Use this location")
                .frame(maxWidth: 300)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom, 25)
    }
}

struct ReportLocationView_Previews: PreviewProvider {
    @State static var draft: ReportDraft = .empty
    static var previews: some View {
        NavigationView {
            ReportLocationView()
        }
    }
}

import CoreLocation
import CoreLocationUI
import MapKit
import SwiftUI

struct ReportLocationView: View {

    @ObservedObject var model: ReportLocationViewModel

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
    }

    private var map: some View {
        Map(
            coordinateRegion: model.$currentDraft.locationRegion,
            showsUserLocation: true
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

    private var locationButton: some View {
        LocationButton(.currentLocation) {
            model.locationManager.requestLocation()
        }
        .foregroundColor(.init(uiColor: .white))
        .labelStyle(.iconOnly)
        .cornerRadius(25)
    }

    private var continueButton: some View {
        NavigationLink {
            ReportDescriptionView(currentDraft: model.$currentDraft)
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
            ReportLocationView(model: ReportLocationViewModel(currentDraft: $draft))
        }
    }
}

import MapKit
import SwiftUI

struct ReportDescriptionView: View {
    @Binding var currentDraft: ReportDraft

    private var region: Binding<MKCoordinateRegion>

    init(currentDraft: Binding<ReportDraft>) {
        _currentDraft = currentDraft
        region = .init(projectedValue: currentDraft.locationRegion)
    }

    var body: some View {
        List {
            Section {
                Map(
                    coordinateRegion: region,
                    interactionModes: []
                )
                .frame(height: 120)
            }
            Section {
                Text("Describe where this place is so it's easier to find it:")
                TextEditor(text: $currentDraft.placeDescription)
                    .frame(height: 240)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Description")
    }
}

struct ReportDescriptionView_Previews: PreviewProvider {
    @State static var draft: ReportDraft = .empty
    static var previews: some View {
        ReportDescriptionView(currentDraft: $draft)
    }
}

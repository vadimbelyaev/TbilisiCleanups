import MapKit
import SwiftUI

struct ReportDescriptionView: View {
    @EnvironmentObject var appState: AppState
    @State private var textEditorBecomeFocused = false
    @State private var textEditorResignFocused = false
    @State private var region: MKCoordinateRegion = .init()
    @State private var location: CLLocationCoordinate2D = .init()
    @Namespace private var textEditorID

    var body: some View {
        ZStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        map
                        labeledTextEditor(scrollProxy: scrollProxy)
                        OverlayNavigationLink(title: "Submit") {
                            ReportSubmissionView()
                        } auxiliaryView: {
                            EmptyView()
                        }
                        .disabled(appState.currentDraft.hasEmptyDescription)
                        .padding(.vertical)
                    }
                }
            }
        }
        .onTapGesture {
            textEditorResignFocused = true
        }
        .navigationTitle("Description")
        .onAppear {
            region = MKCoordinateRegion(
                center: appState.currentDraft.location.clLocationCoordinate2D,
                span: appState.currentDraft.locationRegion.mkCoordinateRegion.span
            )
            location = appState.currentDraft.location.clLocationCoordinate2D
        }
    }

    private var map: some View {
        ReportLocationMapRepresentable(
            region: $region,
            location: $location,
            isInteractive: false
        )
        .frame(height: 120)
    }

    @ViewBuilder
    private func labeledTextEditor(scrollProxy: ScrollViewProxy) -> some View {
        Text("Describe where this place is so it's easier to find it:")
            .padding(.top)
            .padding(.horizontal)
        UITextViewRepresentable(
            text: $appState.currentDraft.placeDescription,
            becomeFocused: $textEditorBecomeFocused,
            resignFocused: $textEditorResignFocused
        )
        .id(textEditorID)
        .frame(height: 120)
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder()
                .foregroundStyle(.tertiary)
        )
        .padding(.horizontal)
        .highPriorityGesture(TapGesture())
        .onAppear {
            textEditorBecomeFocused = true
        }
        .onDisappear {
            textEditorResignFocused = true
        }
    }
}

struct ReportDescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        ReportDescriptionView()
    }
}

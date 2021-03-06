import MapKit
import SwiftUI

struct ReportDescriptionView: View {
    @EnvironmentObject var appState: AppState
    @FocusState private var textEditorFocused: Bool
    @State private var region: MKCoordinateRegion = .init()
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
                        .padding(.vertical)
                    }
                }
            }
        }
        .onTapGesture {
            textEditorFocused = false
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ReportSubmissionView()
                } label: {
                    Text("Submit")
                }

            }
        }
        .navigationTitle("Description")
        .onAppear {
            region = appState.currentDraft.locationRegion.mkCoordinateRegion
        }
    }

    private var map: some View {
        Map(
            coordinateRegion: $region,
            interactionModes: []
        )
        .frame(height: 120)
    }

    @ViewBuilder
    private func labeledTextEditor(scrollProxy: ScrollViewProxy) -> some View {
        Text("Describe where this place is so it's easier to find it:")
            .padding(.top)
            .padding(.horizontal)
        TextEditor(text: $appState.currentDraft.placeDescription)
            .id(textEditorID)
            .focused($textEditorFocused)
            .frame(height: 120)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder()
                    .foregroundStyle(.tertiary)
            )
            .padding(.horizontal)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(750)) {
                    withAnimation {
                        textEditorFocused = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                    withAnimation {
                        scrollProxy.scrollTo(textEditorID)
                    }
                }
            }
    }
}

struct ReportDescriptionView_Previews: PreviewProvider {
    static var previews: some View {
        ReportDescriptionView()
    }
}

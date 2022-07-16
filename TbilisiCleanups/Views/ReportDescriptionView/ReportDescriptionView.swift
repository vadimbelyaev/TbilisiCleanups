import MapKit
import SwiftUI

struct ReportDescriptionView: View {
    @EnvironmentObject private var currentDraft: ReportDraft
    @FocusState private var textEditorFocused: Bool

    @State private var region: MKCoordinateRegion = .init()

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Map(
                        coordinateRegion: $region,
                        interactionModes: []
                    )
                    .frame(height: 120)
                    Text("Describe where this place is so it's easier to find it:")
                        .padding(.top)
                        .padding(.horizontal)
                    TextEditor(text: $currentDraft.placeDescription)
                        .focused($textEditorFocused)
                        .frame(height: 240)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder()
                                .foregroundStyle(.tertiary)
                        )
                        .padding(.horizontal)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(750)) {
                                textEditorFocused = true
                            }
                        }

                }
            }
            HStack {
                Spacer()
                continueButton
                Spacer()
            }
        }
        .onTapGesture {
            textEditorFocused = false
        }
        .navigationTitle("Description")
        .onAppear {
            region = currentDraft.locationRegion
        }
    }

    private var continueButton: some View {
        NavigationLink {
            ReportPhotosView()
        } label: {
            Text("Continue")
                .frame(maxWidth: 300)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom, 25)
    }
}

struct ReportDescriptionView_Previews: PreviewProvider {
    @State static var draft: ReportDraft = .empty
    static var previews: some View {
        ReportDescriptionView()
    }
}

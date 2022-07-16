import SwiftUI
import MapKit

struct ReportPhotosView: View {
    @EnvironmentObject var currentDraft: ReportDraft
    @StateObject var model: ReportPhotosViewModel = .init()
    @State private var isPickerPresented = false
    @State private var isSettingsAlertPresented = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Show us what a littered place you found looks like:")
                    grid
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            OverlayNavigationLink(
                title: "Continue",
                isDisabled: model.currentDraft.medias.isEmpty
            ) {
                ReportLocationView()
            } auxiliaryView: {
                EmptyView()
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            model.makePhotoPicker(isPresented: $isPickerPresented)
        }
        .navigationTitle("Photos")
        .onAppear {
            model.setUpBindings(currentDraft: currentDraft)
        }
    }

    private var grid: some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .adaptive(minimum: 125, maximum: 250),
                    spacing: 8,
                    alignment: .topLeading
                )
            ],
            alignment: .leading,
            spacing: 8
        ) {
            mediaCells
            addPhotosButton
        }
    }

    @ViewBuilder
    private var mediaCells: some View {
        ForEach(currentDraft.medias) { media in
            MediaCell(placeMedia: media)
                .aspectRatio(1, contentMode: .fill)
                .contextMenu {
                    Button {
                        withAnimation {
                            currentDraft.remove(media: media)
                        }
                    } label: {
                        Text("Remove")
                    }
                }
        }
    }

    private var addPhotosButton: some View {
        Button {
            Task {
                await model.startPhotoPickerPresentationFlow(
                    isPickerPresented: $isPickerPresented,
                    isSettingsAlertPresented: $isSettingsAlertPresented
                )
            }
        } label: {
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: model.canPresentPhotoPicker ? "plus" : "rectangle.on.rectangle.slash")
                        .font(.largeTitle)
                    if model.canPresentPhotoPicker {
                        Text("Add photos or videos")
                    } else {
                        Text("Allow access to photos")
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.selection)
        )
        .photoSettingsAlert(isPresented: $isSettingsAlertPresented)
    }
}

private extension View {
    func photoSettingsAlert(isPresented: Binding<Bool>) -> some View {
        alert(
            "Please allow access to photos in the Settings app.",
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

struct MediaCell: View {
    private let placeMedia: PlaceMedia
    @State private var image: UIImage? = nil

    init(placeMedia: PlaceMedia) {
        self.placeMedia = placeMedia
    }

    var body: some View {
        GeometryReader { geometry in
            Color.secondary
                .opacity(0.1)
                .overlay(imageOverlay)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .task {
                    image = await placeMedia.fetchThumbnail(
                        for: geometry.frame(in: .local).size
                    )
                }
        }
    }

    @ViewBuilder
    private var imageOverlay: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }
}

struct ReportPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        ReportPhotosView()
    }
}

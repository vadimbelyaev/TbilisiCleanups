import MapKit
import Photos
import SwiftUI

struct ReportPhotosView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var model: ReportPhotosViewModel = .init()
    @State private var isPickerPresented = false
    @State private var isCustomPickerPresented = false
    @State private var isSettingsAlertPresented = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.ReportPhoto.body)
                    grid
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            OverlayNavigationLink(
                title: L10n.Navigation.continue,
                isDisabled: appState.currentDraft.medias.isEmpty
            ) {
                ReportLocationView()
            } auxiliaryView: {
                EmptyView()
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        model.updateDraftLocationBasedOnPhotos()
                    }
            )
        }
        .sheet(isPresented: $isPickerPresented) {
            model.makePhotoPicker(isPresented: $isPickerPresented)
                .ignoresSafeArea(.all, edges: .bottom)
        }
        .sheet(isPresented: $isCustomPickerPresented) {
            model.makeCustomPhotoPicker(isPresented: $isCustomPickerPresented)
        }
        .navigationTitle(L10n.ReportPhoto.title)
        .onAppear {
            model.setUpBindings(appState: appState)
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
        ForEach(appState.currentDraft.medias) { media in
            MediaCell(model: model, placeMedia: media)
                .aspectRatio(1, contentMode: .fill)
                .contextMenu {
                    Button {
                        withAnimation {
                            appState.currentDraft.remove(media: media)
                        }
                    } label: {
                        Text(L10n.ReportPhoto.removeMenu)
                    }
                }
        }
    }

    private var addPhotosButton: some View {
        Button {
            Task {
                await model.startPhotoPickerPresentationFlow(
                    isPickerPresented: $isPickerPresented,
                    isLimitedPickerPresented: $isCustomPickerPresented,
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
                        Text(L10n.ReportPhoto.addPhotosButton)
                    } else {
                        Text(L10n.ReportPhoto.allowAccess)
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
            L10n.ReportPhoto.AccessAlert.title,
            isPresented: isPresented,
            actions: {
                Button(role: .cancel) {
                    // no-op
                } label: {
                    Text(L10n.ReportPhoto.AccessAlert.notNowAction)
                }
                Button {
                    UIApplication.goToSettings()
                } label: {
                    Text(L10n.ReportPhoto.AccessAlert.settingsAction)
                }
            }
        )
    }
}

struct MediaCell: View {
    @ObservedObject private var model: ReportPhotosViewModel
    private let placeMedia: PlaceMedia
    @State private var asset: PHAsset?
    @State private var image: UIImage?

    init(
        model: ReportPhotosViewModel,
        placeMedia: PlaceMedia
    ) {
        self.model = model
        self.placeMedia = placeMedia
    }

    var body: some View {
        GeometryReader { geometry in
            Color.secondary
                .opacity(0.1)
                .overlay(imageOverlay)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(videoDurationOverlay)
                .task {
                    do {
                        let fetchedAsset = try await model.fetchAsset(for: placeMedia)
                        asset = fetchedAsset
                        image = try await model.fetchThumbnail(
                            for: fetchedAsset,
                            ofSize: geometry.frame(in: .local).size
                        )
                    } catch {
                        AnalyticsService.logEvent(AppError.couldNotFetchThumbnail(innerError: error))
                    }
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

    @ViewBuilder
    private var videoDurationOverlay: some View {
        if let asset = asset,
           asset.mediaType == .video
        {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(model.formattedDuration(for: asset))
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.4).blur(radius: 4))
                }
            }
        }
    }
}

struct ReportPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        ReportPhotosView()
    }
}

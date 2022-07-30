import AVFoundation
import FirebaseCrashlytics
import MapKit
import os.log
import Photos
import SwiftUI

@MainActor
final class ReportPhotosViewModel: ObservableObject {
    @ObservedObject var appState: AppState = .init()
    @Published var authorization: PHAuthorizationStatus
    private let imageManager = PHImageManager.default()
    private let assetsCache = NSCache<NSString, PHAsset>()

    init() {
        authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func setUpBindings(appState: AppState) {
        self.appState = appState
    }

    var canPresentPhotoPicker: Bool {
        [.notDetermined, .authorized, .limited].contains(authorization)
    }

    func startPhotoPickerPresentationFlow(
        isPickerPresented: Binding<Bool>,
        isSettingsAlertPresented: Binding<Bool>
    ) async {
        switch authorization {
        case .notDetermined:
            authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if [.authorized, .limited].contains(authorization) {
                isPickerPresented.wrappedValue = true
            }
        case .authorized, .limited:
            isPickerPresented.wrappedValue = true
        case .restricted, .denied:
            isSettingsAlertPresented.wrappedValue = true
        @unknown default:
            assertionFailure()
            return
        }
    }

    func makePhotoPicker(isPresented: Binding<Bool>) -> some View {
        PhotoPicker(results: $appState.currentDraft.medias, isPresented: isPresented)
    }

    func makeCustomPhotoPicker(isPresented: Binding<Bool>) -> some View {
        let appState = self.appState
        return CustomPhotoPicker(didFinishPicking: { assets in
            let newMedias = assets.map { PlaceMedia(assetId: $0.localIdentifier) }
            appState.currentDraft.medias.append(contentsOf: newMedias)
        })
    }

    func getFirstLocationOfSelectedPhotos() -> CLLocation? {
        let ids = appState.currentDraft.medias.map(\.assetId)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var targetLocation: CLLocation?
        fetchResult.enumerateObjects { asset, _, stop in
            if let location = asset.location {
                targetLocation = location
                stop.pointee = true
            }
        }
        return targetLocation
    }

    func updateDraftLocationBasedOnPhotos() {
        guard appState.currentDraft.locationRegion == ReportDraft.defaultRegion,
              appState.currentDraft.location == ReportDraft.defaultLocation,
              let location = getFirstLocationOfSelectedPhotos()
        else { return }

        appState.currentDraft.locationRegion = .init(
            region: MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
        appState.currentDraft.location = .init(clLocationCoordinate2D: location.coordinate)
    }

    func fetchThumbnail(for placeMedia: PlaceMedia, ofSize size: CGSize) async -> UIImage? {
        guard [.authorized, .limited].contains(PHPhotoLibrary.authorizationStatus(for: .readWrite)) else {
            return nil
        }
        return await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            Task.detached(priority: .userInitiated) { [weak self] in
                guard let self = self else { return }
                let asset: PHAsset? = {
                    if let cachedAsset = self.assetsCache.object(forKey: NSString(string: placeMedia.assetId)) {
                        return cachedAsset
                    }
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [placeMedia.assetId], options: nil)
                    guard let asset = fetchResult.firstObject else {
                        return nil
                    }
                    return asset
                }()
                guard let asset = asset else {
                    continuation.resume(returning: nil)
                    return
                }
                self.assetsCache.setObject(asset, forKey: NSString(string: asset.localIdentifier))
                let scale = await UIScreen.main.scale
                let targetSize = CGSize(
                    width: size.width * scale,
                    height: size.height * scale
                )

                let options = PHImageRequestOptions()
                options.isSynchronous = true
                options.resizeMode = .fast
                options.deliveryMode = .highQualityFormat
                self.imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    continuation.resume(returning: image)
                }
            }
        }
    }
}

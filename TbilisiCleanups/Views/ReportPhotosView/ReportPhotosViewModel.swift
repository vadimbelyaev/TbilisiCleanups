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
        isLimitedPickerPresented: Binding<Bool>,
        isSettingsAlertPresented: Binding<Bool>
    ) async {
        switch authorization {
        case .notDetermined:
            authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if authorization == .authorized {
                isPickerPresented.wrappedValue = true
            } else if authorization == .limited {
                isLimitedPickerPresented.wrappedValue = true
            }
        case .authorized:
            isPickerPresented.wrappedValue = true
        case .limited:
            isLimitedPickerPresented.wrappedValue = true
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
        let pickerL10n = CustomPhotoPickerL10n(
            navigationTitle: L10n.CustomPhotoPicker.navigationTitle,
            toolbarCancelButton: L10n.CustomPhotoPicker.toolbarCancelButton,
            toolbarAddButton: L10n.CustomPhotoPicker.toolbarAddButton,
            limitedAccessDisclaimer: L10n.CustomPhotoPicker.limitedAccessDisclaimer,
            selectMorePhotosButton: L10n.CustomPhotoPicker.selectMorePhotosButton
        )
        return CustomPhotoPicker(
            pickerL10n: pickerL10n,
            didFinishPicking: { assets in
                let newMedias = assets.map { PlaceMedia(assetId: $0.localIdentifier) }
                appState.currentDraft.medias.append(contentsOf: newMedias)
            }
        )
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

    func fetchAsset(for placeMedia: PlaceMedia) async throws -> PHAsset {
        guard [.authorized, .limited].contains(PHPhotoLibrary.authorizationStatus(for: .readWrite)) else {
            throw ImageFetchError.noPhotoLibraryPermissions
        }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<PHAsset, Error>) in
            Task.detached(priority: .userInitiated) { [weak self] in
                guard let self = self else {
                    throw ImageFetchError.cancelled
                }
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
                    continuation.resume(throwing: ImageFetchError.assetNotFound)
                    return
                }
                self.assetsCache.setObject(asset, forKey: NSString(string: asset.localIdentifier))
                continuation.resume(returning: asset)
            }
        }
    }

    func fetchThumbnail(for asset: PHAsset, ofSize size: CGSize) async throws -> UIImage {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UIImage, Error>) in
            Task.detached(priority: .userInitiated) { [weak self] in
                guard let self = self else {
                    throw ImageFetchError.cancelled
                }
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
                    if let image = image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: ImageFetchError.cannotFetchThumbnail)
                    }
                }
            }
        }
    }

    func formattedDuration(for asset: PHAsset) -> String {
        Self.durationFormatter.string(from: asset.duration) ?? ""
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let fmt = DateComponentsFormatter()
        fmt.allowsFractionalUnits = false
        fmt.allowedUnits = [.second, .minute]
        fmt.zeroFormattingBehavior = .dropTrailing
        return fmt
    }()
}

enum ImageFetchError: Error {
    case noPhotoLibraryPermissions
    case assetNotFound
    case cannotFetchThumbnail
    case cancelled
}

import FirebaseCrashlytics
import os.log
import SwiftUI
import AVFoundation
import Photos

@MainActor
final class ReportPhotosViewModel: ObservableObject {
    @ObservedObject var currentDraft: ReportDraft = .empty
    @Published var authorization: PHAuthorizationStatus
    private let imageManager = PHImageManager()

    init() {
        authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func setUpBindings(currentDraft: ReportDraft) {
        self.currentDraft = currentDraft
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
        PhotoPicker(results: $currentDraft.medias, isPresented: isPresented)
    }

    func getFirstLocationOfSelectedPhotos() -> CLLocation? {
        let ids = currentDraft.medias.map(\.id)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var targetLocation: CLLocation? = nil
        fetchResult.enumerateObjects { asset, _, stop in
            if let location = asset.location {
                targetLocation = location
                stop.pointee = true
            }
        }
        return targetLocation
    }

    func updateDraftLocationBasedOnPhotos() {
        guard let location = getFirstLocationOfSelectedPhotos() else {
            return
        }
        currentDraft.locationRegion.center = location.coordinate
    }
}

extension PlaceMedia {

    func fetchThumbnail(for size: CGSize) async -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        let scale = await UIScreen.main.scale
        let targetSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        return await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.resizeMode = .fast
            options.deliveryMode = .highQualityFormat
            imageManager.requestImage(
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

private let logger = Logger()
private let imageManager = PHImageManager()

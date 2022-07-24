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

    func getFirstLocationOfSelectedPhotos() -> CLLocation? {
        let ids = appState.currentDraft.medias.map(\.id)
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
        guard appState.currentDraft.locationRegion == ReportDraft.defaultLocation,
              let location = getFirstLocationOfSelectedPhotos()
        else { return }

        appState.currentDraft.locationRegion = .init(
            region: MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }
}

extension PlaceMedia {
    func fetchThumbnail(for size: CGSize) async -> UIImage? {
        guard [.authorized, .limited].contains(PHPhotoLibrary.authorizationStatus(for: .readWrite)) else {
            return nil
        }
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
            PHImageManager.default().requestImage(
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

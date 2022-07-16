import FirebaseCrashlytics
import os.log
import SwiftUI
import AVFoundation
import Photos

@MainActor
final class ReportPhotosViewModel: ObservableObject {
    @ObservedObject var currentDraft: ReportDraft = .empty
    @Published var authorization: PHAuthorizationStatus

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
}

extension PlaceMedia {

//    enum ImageLoadingError: Error {
//        case itemProviderCannotLoadAcceptedFormats
//        case itemProviderLoadError(innerError: Error)
//        case itemProviderReturnedNonUIImage
//        case couldNotCreateThumbnail
//    }
//
//    enum VideoExportError: Error {
//        case itemProviderLoadFileError(innerError: Error)
//        case itemProviderDidNotReturnURL
//        case cachesDirectoryInaccessible
//        case fileCopyFailed(innerError: Error)
//    }
//
//    private typealias ImageContinuation = CheckedContinuation<UIImage, Error>
//
//    @MainActor
//    func loadThumbnail(for size: CGSize) async throws -> UIImage {
//        if itemProvider.canLoadObject(ofClass: UIImage.self) {
//            let fullSizeImage = try await loadFullSizeImage()
//            return try await makeThumbnail(from: fullSizeImage, size: size)
//        } else if itemProvider.hasRepresentationConforming(toTypeIdentifier: UTType.movie.identifier) {
//            let url = try await saveVideo()
//            return UIImage()
//        } else {
//            logger.error("Error fetching image: item provider can't load any of accepted formats")
//            let error = ImageLoadingError.itemProviderCannotLoadAcceptedFormats
//            Crashlytics.crashlytics().record(error: error)
//            throw error
//        }
//    }
//
//    func loadFullSizeImage() async throws -> UIImage {
//        return try await withCheckedThrowingContinuation { (continuation: ImageContinuation) in
//            itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
//                guard let fullSizeImage = reading as? UIImage else {
//                    if let error = error {
//                        logger.error("Error fetching image: \(error.localizedDescription, privacy: .public)")
//                        let errorToThrow = ImageLoadingError.itemProviderLoadError(innerError: error)
//                        Crashlytics.crashlytics().record(error: errorToThrow)
//                        continuation.resume(throwing: errorToThrow)
//                    } else {
//                        logger.error("Error fetching image: not a UIImage")
//                        let error = ImageLoadingError.itemProviderReturnedNonUIImage
//                        Crashlytics.crashlytics().record(error: error)
//                        continuation.resume(throwing: error)
//                    }
//                    return
//                }
//                continuation.resume(returning: fullSizeImage)
//            }
//        }
//    }
//
//    func saveVideo() async throws -> URL {
//        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
//            itemProvider.loadFileRepresentation(
//                forTypeIdentifier: UTType.movie.identifier
//            ) { url, error in
//                guard let url = url else {
//                    if let error = error {
//                        logger.error("Error saving video from photo library: \(error.localizedDescription)")
//                        let error = VideoExportError.itemProviderLoadFileError(innerError: error)
//                        Crashlytics.crashlytics().record(error: error)
//                        continuation.resume(throwing: error)
//                    } else {
//                        logger.error("Error saving video from photo library: item provider did not return a URL")
//                        let error = VideoExportError.itemProviderDidNotReturnURL
//                        Crashlytics.crashlytics().record(error: error)
//                        continuation.resume(throwing: error)
//                    }
//                    return
//                }
//                let fileManager = FileManager.default
//                guard let cachesDirectory = fileManager.urls(
//                        for: .cachesDirectory,
//                        in: .userDomainMask
//                    )
//                    .first
//                else {
//                    logger.error("Error saving video from photo library: caches directory is inaccessible")
//                    let error = VideoExportError.cachesDirectoryInaccessible
//                    Crashlytics.crashlytics().record(error: error)
//                    continuation.resume(throwing: error)
//                    return
//                }
//                let targetURL = URL(fileURLWithPath: UUID().uuidString, relativeTo: cachesDirectory)
//                do {
//                    try FileManager.default.copyItem(at: url, to: targetURL)
//                    continuation.resume(returning: targetURL)
//                } catch {
//                    logger.error("Error saving video from photo library. File copying failed: \(error.localizedDescription)")
//                    let error = VideoExportError.fileCopyFailed(innerError: error)
//                    Crashlytics.crashlytics().record(error: error)
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//
//    @MainActor func makeThumbnail(from image: UIImage, size: CGSize) async throws -> UIImage {
//        let scale = UIScreen.main.scale
//        return try await withCheckedThrowingContinuation { (continuation: ImageContinuation) in
//            let fullSize = image.size
//            let maxThumbnailDimension = max(size.width, size.height) * scale
//            let aspectRatio = fullSize.height > 0 ? fullSize.width / fullSize.height : 0
//            let thumbnailSize = CGSize(
//                width: aspectRatio >= 1 ? maxThumbnailDimension * aspectRatio : maxThumbnailDimension,
//                height: aspectRatio < 1 ? maxThumbnailDimension * aspectRatio : maxThumbnailDimension
//            )
//            guard let thumbnail = image.preparingThumbnail(of: thumbnailSize) else {
//                logger.error("Error fetching image: could not create a thumbnail")
//                let error = ImageLoadingError.couldNotCreateThumbnail
//                Crashlytics.crashlytics().record(error: error)
//                continuation.resume(throwing: error)
//                return
//            }
//            continuation.resume(returning: thumbnail)
//        }
//    }
}

private let logger = Logger()

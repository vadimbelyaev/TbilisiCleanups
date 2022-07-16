import FirebaseCrashlytics
import os.log
import SwiftUI

final class ReportPhotosViewModel: ObservableObject {
    @Binding var currentDraft: ReportDraft

    init(currentDraft: Binding<ReportDraft>) {
        _currentDraft = currentDraft
    }

    func makePhotoPicker(isPresented: Binding<Bool>) -> some View {
        PhotoPicker(results: $currentDraft.medias, isPresented: isPresented)
    }
}

extension PlaceMedia {

    enum ImageLoadingError: Error {
        case itemProviderCannotLoadUIImage
        case itemProviderLoadError(innerError: Error)
        case itemProviderReturnedNonUIImage
        case couldNotCreateThumbnail
    }

    private typealias ImageContinuation = CheckedContinuation<UIImage, Error>

    @MainActor
    func loadThumbnail(for size: CGSize) async throws -> UIImage {
        guard itemProvider.canLoadObject(ofClass: UIImage.self) else {
            logger.error("Error fetching image: item provider can't load a UIImage")
            let error = ImageLoadingError.itemProviderCannotLoadUIImage
            Crashlytics.crashlytics().record(error: error)
            throw error
        }
        let fullSizeImage = try await loadFullSizeImage()
        return try await makeThumbnail(from: fullSizeImage, size: size)
    }

    func loadFullSizeImage() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { (continuation: ImageContinuation) in
            itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
                guard let fullSizeImage = reading as? UIImage else {
                    if let error = error {
                        logger.error("Error fetching image: \(error.localizedDescription, privacy: .public)")
                        let errorToThrow = ImageLoadingError.itemProviderLoadError(innerError: error)
                        Crashlytics.crashlytics().record(error: errorToThrow)
                        continuation.resume(throwing: errorToThrow)
                    } else {
                        logger.error("Error fetching image: not a UIImage")
                        let error = ImageLoadingError.itemProviderReturnedNonUIImage
                        Crashlytics.crashlytics().record(error: error)
                        continuation.resume(throwing: error)
                    }
                    return
                }
                continuation.resume(returning: fullSizeImage)
            }
        }
    }

    @MainActor func makeThumbnail(from image: UIImage, size: CGSize) async throws -> UIImage {
        let scale = UIScreen.main.scale
        return try await withCheckedThrowingContinuation { (continuation: ImageContinuation) in
            let fullSize = image.size
            let maxThumbnailDimension = max(size.width, size.height) * scale
            let aspectRatio = fullSize.height > 0 ? fullSize.width / fullSize.height : 0
            let thumbnailSize = CGSize(
                width: aspectRatio >= 1 ? maxThumbnailDimension * aspectRatio : maxThumbnailDimension,
                height: aspectRatio < 1 ? maxThumbnailDimension * aspectRatio : maxThumbnailDimension
            )
            guard let thumbnail = image.preparingThumbnail(of: thumbnailSize) else {
                logger.error("Error fetching image: could not create a thumbnail")
                let error = ImageLoadingError.couldNotCreateThumbnail
                Crashlytics.crashlytics().record(error: error)
                continuation.resume(throwing: error)
                return
            }
            continuation.resume(returning: thumbnail)
        }
    }
}

private let logger = Logger()

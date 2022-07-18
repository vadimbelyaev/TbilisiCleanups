import Photos

final class ReportService: ObservableObject {
    private let appState: AppState
    private let s3Service: S3Service

    init(appState: AppState) {
        self.appState = appState
        do {
            self.s3Service = try S3Service()
        } catch {
            fatalError("Could not create an S3Service")
        }
    }

    func submitCurrentDraft() async throws {
        // Prepare media for upload
        let medias = await appState.currentDraft.medias
        let ids = medias.map(\.id)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        let assetsByType = classifyAssetsByType(from: fetchResult)
        let s3Service = self.s3Service
        let timestamp = Date().timeIntervalSince1970
        try Task.checkCancellation()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for imageAsset in assetsByType.images {
                group.addTask(priority: .low) {
                    try Task.checkCancellation()
                    let data = try await dataForImageAsset(imageAsset)
                    try Task.checkCancellation()
                    try await s3Service.upload(
                        data: data,
                        withKey: storageKey(
                            for: imageAsset,
                            timestamp: timestamp
                        ),
                        contentType: "image/jpeg"
                    )
                }
            }
            try await group.waitForAll()
        }
    }


//    func exportSessionForVideoAsset(_ asset: PHAsset) async throws -> AVAssetExportSession {
//        let options = PHVideoRequestOptions()
//        options.deliveryMode = .fastFormat
//        options.version = .current
//        imageManager.requestExportSession(
//            forVideo: <#T##PHAsset#>,
//            options: <#T##PHVideoRequestOptions?#>,
//            exportPreset: String
//        ) { <#AVAssetExportSession?#>, <#[AnyHashable : Any]?#> in
//                <#code#>
//            }
//
//    }
}

private struct AssetsByType {
    let images: [PHAsset]
    let videos: [PHAsset]
}

private func classifyAssetsByType(
    from fetchResult: PHFetchResult<PHAsset>
) -> AssetsByType {
    var images: [PHAsset] = []
    var videos: [PHAsset] = []
    fetchResult.enumerateObjects { asset, _, _ in
        switch asset.mediaType {
        case .image:
            images.append(asset)
        case .video:
            videos.append(asset)
        case .audio, .unknown:
            break
        @unknown default:
            assertionFailure()
            break
        }
    }
    return AssetsByType(images: images, videos: videos)
}

private func dataForImageAsset(_ asset: PHAsset) async throws -> Data {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isSynchronous = true
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: exportSize(for: asset),
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            guard let image = image else {
                continuation.resume(throwing: MediaExportError.imageExportReturnedNoData)
                return
            }
            guard let data = image.jpegData(compressionQuality: 0.51) else {
                continuation.resume(throwing: MediaExportError.cannotGetJPEGRepresentation)
                return
            }
            continuation.resume(returning: data)
        }
    }
}

private func exportSize(for asset: PHAsset) -> CGSize {
    let width = Double(asset.pixelWidth)
    let height = Double(asset.pixelHeight)
    let lesserDimension = 1080.0 * 2.0
    guard min(width, height) > lesserDimension else {
        return CGSize(width: width, height: height)
    }
    let aspectRatio = height > 0 ? width / height : 0
    guard aspectRatio > 0 else {
        return .zero
    }
    let targetWidth = width > height ? lesserDimension * aspectRatio : lesserDimension
    let targetHeight = width > height ? lesserDimension : lesserDimension / aspectRatio
    return CGSize(width: Int(targetWidth), height: Int(targetHeight))
}

private func storageKey(
    for asset: PHAsset,
    timestamp: TimeInterval
) -> String {
    "user_media-\(UUID().uuidString)-\(Int(timestamp)).jpg"
}

enum MediaExportError: Error {
    case imageExportReturnedNoData
    case cannotGetJPEGRepresentation
}

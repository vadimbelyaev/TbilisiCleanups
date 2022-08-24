import Photos

final class MediaUploadService {
    private let s3Service: S3Service

    // MARK: - Lifecycle

    init() {
        do {
            self.s3Service = try S3Service()
        } catch {
            fatalError("Could not create an S3Service")
        }
    }

    // MARK: - Public Interface

    /// Exports medias to appropriate formats and uploads them to S3.
    /// - Parameter medias: Medias to upload.
    /// - Returns: A collection of medias that have the `publicURL` property populated.
    func uploadMedias(_ medias: [PlaceMedia]) async throws -> UploadedMediasByType {
        let ids = medias.map(\.assetId)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        let assetsByType = classifyAssetsByType(from: fetchResult)
        let s3Service = self.s3Service
        let timestamp = Date().timeIntervalSince1970
        try Task.checkCancellation()
        var uploadedPhotos: [UploadedMedia] = []
        var uploadedVideos: [UploadedMedia] = []
        try await withThrowingTaskGroup(of: UploadedMedia.self) { group in
            for imageAsset in assetsByType.images {
                group.addTask(priority: .low) {
                    try await uploadImageAsset(
                        asset: imageAsset,
                        using: s3Service,
                        timestamp: timestamp
                    )
                }
            }
            for try await uploadedMedia in group {
                uploadedPhotos.append(uploadedMedia)
            }
        }
        try await withThrowingTaskGroup(of: UploadedMedia.self) { group in
            for videoAsset in assetsByType.videos {
                group.addTask(priority: .low) {
                    try await uploadVideoAsset(
                        asset: videoAsset,
                        using: s3Service,
                        timestamp: timestamp
                    )
                }
            }
            for try await uploadedMedia in group {
                uploadedVideos.append(uploadedMedia)
            }
        }
        return UploadedMediasByType(photos: uploadedPhotos, videos: uploadedVideos)
    }
}

// MARK: - Image Uploading

private func uploadImageAsset(
    asset: PHAsset,
    using s3Service: S3Service,
    timestamp: TimeInterval
) async throws -> UploadedMedia {
    try Task.checkCancellation()
    let data = try await dataForImageAsset(asset, size: exportSize(for: asset))
    try Task.checkCancellation()
    let uploadedMediaId = UUID().uuidString
    let url = try await s3Service.upload(
        data: data,
        withKey: makeStorageKey(
            uploadedMediaId: uploadedMediaId,
            timestamp: timestamp,
            fileExtension: "jpg"
        ),
        contentType: "image/jpeg"
    )
    try Task.checkCancellation()
    let previewImageData = try await dataForImageAsset(asset, size: previewImageSize(for: asset))
    try Task.checkCancellation()
    let previewImageURL = try await s3Service.upload(
        data: previewImageData,
        withKey: makePreviewImageStorageKey(
            uploadedMediaId: uploadedMediaId,
            timestamp: timestamp,
            assetFileExtension: "jpg",
            previewFileExtension: "jpg"
        ),
        contentType: "image/jpeg"
    )

    return UploadedMedia(
        id: uploadedMediaId,
        assetId: asset.localIdentifier,
        url: url,
        previewImageURL: previewImageURL,
        width: asset.pixelWidth,
        height: asset.pixelHeight
    )
}

private func dataForImageAsset(_ asset: PHAsset, size: CGSize) async throws -> Data {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: makeImageRequestOptions()
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

private func makeImageRequestOptions() -> PHImageRequestOptions {
    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .exact
    options.isNetworkAccessAllowed = true
    options.isSynchronous = true
    return options
}

private func exportSize(for imageAsset: PHAsset) -> CGSize {
    imageSize(withLesserDimensionEqualTo: 1080 * 2, for: imageAsset)
}

private func previewImageSize(for asset: PHAsset) -> CGSize {
    imageSize(withLesserDimensionEqualTo: 256 * 2, for: asset)
}

private func imageSize(
    withLesserDimensionEqualTo lesserDimension: Double,
    for asset: PHAsset
) -> CGSize {
    let width = Double(asset.pixelWidth)
    let height = Double(asset.pixelHeight)
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

// MARK: - Video Uploading

private func uploadVideoAsset(
    asset: PHAsset,
    using s3Service: S3Service,
    timestamp: TimeInterval
) async throws -> UploadedMedia {
    try Task.checkCancellation()
    let outputURL = try makeUrlForVideoExportSession()
    let exportSession = try await exportSessionForVideoAsset(asset)
    try Task.checkCancellation()
    exportSession.outputFileType = .mp4
    exportSession.outputURL = outputURL
    exportSession.shouldOptimizeForNetworkUse = true
    await exportSession.export()
    try Task.checkCancellation()
    guard exportSession.status == .completed else {
        throw MediaExportError.avAssetExportSessionFailed
    }
    let data = try Data(contentsOf: outputURL)
    let uploadedMediaId = UUID().uuidString
    let url = try await s3Service.upload(
        data: data,
        withKey: makeStorageKey(
            uploadedMediaId: uploadedMediaId,
            timestamp: timestamp,
            fileExtension: "mp4"
        ),
        contentType: "video/mp4"
    )
    let previewImageData = try await dataForImageAsset(asset, size: previewImageSize(for: asset))
    try Task.checkCancellation()
    let previewImageURL = try await s3Service.upload(
        data: previewImageData,
        withKey: makePreviewImageStorageKey(
            uploadedMediaId: uploadedMediaId,
            timestamp: timestamp,
            assetFileExtension: "mp4",
            previewFileExtension: "jpg"
        ),
        contentType: "image/jpeg"
    )

    return UploadedMedia(
        id: uploadedMediaId,
        assetId: asset.localIdentifier,
        url: url,
        previewImageURL: previewImageURL,
        width: asset.pixelWidth,
        height: asset.pixelHeight
    )
}

private func exportSessionForVideoAsset(_ asset: PHAsset) async throws -> AVAssetExportSession {
    let avAsset = try await fetchAVAsset(for: asset)
    let preset = try await videoExportPreset(for: avAsset)
    return try await withCheckedThrowingContinuation
        { (continuation: CheckedContinuation<AVAssetExportSession, Error>) in
            PHImageManager.default().requestExportSession(
                forVideo: asset,
                options: makeVideoRequestOptions(),
                exportPreset: preset
            ) { session, info in
                guard let session = session else {
                    continuation.resume(throwing: MediaExportError.cannotGetAVAssetExportSession)
                    return
                }
                continuation.resume(returning: session)
            }
        }
}

private func fetchAVAsset(for asset: PHAsset) async throws -> AVAsset {
    try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<AVAsset, Error>) in
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: makeVideoRequestOptions()
        ) { avAsset, audioMix, info in
            guard let avAsset = avAsset else {
                continuation.resume(throwing: MediaExportError.cannotFetchAVAsset)
                return
            }
            continuation.resume(returning: avAsset)
        }
    })
}

private func videoExportPreset(for asset: AVAsset) async throws -> String {
    let preferredPresets = [
        AVAssetExportPresetMediumQuality,
        AVAssetExportPreset1280x720,
        AVAssetExportPresetLowQuality,
        AVAssetExportPreset960x540
    ]
    let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
    let allPresets = preferredPresets + compatiblePresets
    for preset in allPresets {
        let canExport = await AVAssetExportSession.compatibility(
            ofExportPreset: preset,
            with: asset,
            outputFileType: .mp4
        )
        if canExport {
            return preset
        }
    }
    throw MediaExportError.noVideoExportPresetsAvailable
}

private func makeVideoRequestOptions() -> PHVideoRequestOptions {
    let options = PHVideoRequestOptions()
    options.deliveryMode = .mediumQualityFormat
    options.isNetworkAccessAllowed = true
    options.version = .current
    return options
}

private func makeUrlForVideoExportSession() throws -> URL {
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    guard let cachesDir = urls.first else {
        throw MediaExportError.noCachesDirectory
    }
    let fileName = "\(UUID().uuidString).mp4"
    return URL(fileURLWithPath: fileName, relativeTo: cachesDir)
}

// MARK: - Asset Classification

private struct AssetsByType {
    let images: [PHAsset]
    let videos: [PHAsset]
    var cover: PHAsset? {
        images.first ?? videos.first
    }
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
        }
    }
    return AssetsByType(images: images, videos: videos)
}

// MARK: - Storage Keys

private func makeStorageKey(
    uploadedMediaId: String,
    timestamp: TimeInterval,
    fileExtension: String
) -> String {
    String(
        format: "user_media-%@-%d.%@",
        uploadedMediaId,
        Int(timestamp),
        fileExtension
    )
}

private func makePreviewImageStorageKey(
    uploadedMediaId: String,
    timestamp: TimeInterval,
    assetFileExtension: String,
    previewFileExtension: String
) -> String {
    String(
        format: "user_media-%@-%d.%@.thumb.%@",
        uploadedMediaId,
        Int(timestamp),
        assetFileExtension,
        previewFileExtension
    )
}

// MARK: - Error Type

enum MediaExportError: Error {
    case imageExportReturnedNoData
    case cannotGetJPEGRepresentation
    case cannotGetAVAssetExportSession
    case cannotFetchAVAsset
    case noVideoExportPresetsAvailable
    case noCachesDirectory
    case avAssetExportSessionFailed
}

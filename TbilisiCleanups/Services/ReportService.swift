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
                        withKey: makeStorageKey(
                            timestamp: timestamp,
                            fileExtension: "jpg"
                        ),
                        contentType: "image/jpeg"
                    )
                }
            }
            for videoAsset in assetsByType.videos {
                group.addTask(priority: .low) {
                    try Task.checkCancellation()
                    let outputURL = try makeUrlForVideoExportSession()
                    let exportSession = try await exportSessionForVideoAsset(videoAsset)
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
                    try await s3Service.upload(
                        data: data,
                        withKey: makeStorageKey(
                            timestamp: timestamp,
                            fileExtension: "mp4"
                        ),
                        contentType: "video/mp4"
                    )
                }
            }
            try await group.waitForAll()
        }
    }
}

private func exportSessionForVideoAsset(_ asset: PHAsset) async throws -> AVAssetExportSession {
    let avAsset = try await fetchAVAsset(for: asset)
    let preset = try await videoExportPreset(for: avAsset)
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AVAssetExportSession, Error>) in
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
        AVAssetExportPreset960x540,
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
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: exportSize(for: asset),
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

private func makeStorageKey(
    timestamp: TimeInterval,
    fileExtension: String
) -> String {
    "user_media-\(UUID().uuidString)-\(Int(timestamp)).\(fileExtension)"
}

enum MediaExportError: Error {
    case imageExportReturnedNoData
    case cannotGetJPEGRepresentation
    case cannotGetAVAssetExportSession
    case cannotFetchAVAsset
    case noVideoExportPresetsAvailable
    case noCachesDirectory
    case avAssetExportSessionFailed
}

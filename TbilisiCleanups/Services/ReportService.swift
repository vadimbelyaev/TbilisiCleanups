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

        let s3Service = self.s3Service
        try await withThrowingTaskGroup(of: Void.self) { group in
            for imageAsset in images {
                group.addTask(priority: .low) {
                    let data = try await dataForImageAsset(imageAsset)
                    try await s3Service.upload(data: data, withKey: imageAsset.localIdentifier)
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

private func dataForImageAsset(_ asset: PHAsset) async throws -> Data {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isSynchronous = true
        PHImageManager.default().requestImageDataAndOrientation(
            for: asset,
            options: options
        ) { data, dataUTI, orientation, info in
            guard let data = data else {
                continuation.resume(throwing: MediaExportError.imageExportReturnedNoData)
                return
            }
            continuation.resume(returning: data)
        }

    }
}


enum MediaExportError: Error {
    case imageExportReturnedNoData
}

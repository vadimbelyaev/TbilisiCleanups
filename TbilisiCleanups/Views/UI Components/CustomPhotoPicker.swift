import Photos
import SwiftUI

struct CustomPhotoPicker: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var model = CustomPhotoPickerModel()
    @State private var isLimitedLibraryPickerPresented = false

    private let didFinishPicking: (([PHAsset]) -> Void)?

    init(didFinishPicking: (([PHAsset]) -> Void)?) {
        self.didFinishPicking = didFinishPicking
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    grid
                    limitedLibraryAccessView
                }
                .navigationTitle("Photos")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            didFinishPicking?(model.getSelectedAssets())
                            dismiss()
                        } label: {
                            Text("Add")
                        }
                    }
                }
                .task {
                    await model.fetchAssets()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var grid: some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .adaptive(minimum: 100, maximum: 200),
                    spacing: 2,
                    alignment: .topLeading
                )
            ],
            alignment: .center,
            spacing: 2
        ) {
            ForEach(model.assets, id: \.localIdentifier) { asset in
                CustomPhotoPickerCell(asset: asset, model: model)
                    .aspectRatio(1, contentMode: .fill)
                    .tag(asset.localIdentifier)
            }
        }
    }

    private var limitedLibraryAccessView: some View {
        VStack(alignment: .leading) {
            Text("You allowed limited access to your photo library.")
                .font(.footnote)
                .foregroundColor(.secondary)
            Button {
                isLimitedLibraryPickerPresented = true
            } label: {
                Text("Select more photos...")
                    .font(.footnote)
            }
            LimitedLibraryPickerRepresentable(isPresented: $isLimitedLibraryPickerPresented)
        }
        .padding()
    }
}

@MainActor
private struct CustomPhotoPickerCell: View {
    var asset: PHAsset
    @ObservedObject var model: CustomPhotoPickerModel
    @State private var uiImage: UIImage?

    var body: some View {
        GeometryReader { geometry in
            Button {
                model.toggleAssetSelection(asset: asset)
            } label: {
                Color.black.opacity(0.9)
                    .overlay(imageOverlay)
                    .overlay(infoOverlay)
                    .clipShape(Rectangle())
            }
            .task {
                uiImage = await model.fetchThumbnail(
                    for: asset,
                    ofSize: geometry.frame(in: .local).size
                )
            }
        }
    }

    @ViewBuilder
    private var imageOverlay: some View {
        if let uiImage = uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }

    @ViewBuilder
    private var infoOverlay: some View {
        if model.isSelected(asset) {
            ZStack(alignment: .bottomTrailing) {
                Color.black.opacity(0.3)
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.multicolor)
                    .padding(4)
            }
        } else if asset.mediaType == .video {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(model.formattedDuration(for: asset))
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(2)
                        .background(Color.black.opacity(0.4).blur(radius: 4))
                }
            }
        }
    }
}

@MainActor
private final class CustomPhotoPickerModel: NSObject, ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var selectedAssetIDs: Set<String> = []

    private let imageManager: PHImageManager = .default()

    override init() {
        super.init()
        assert(
            PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited,
            "The CustomPhotoPicker is only designed for the limited mode."
        )
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func fetchAssets() async {
        Task(priority: .userInitiated) {
            let allAssets = await withCheckedContinuation { (continuation: CheckedContinuation<[PHAsset], Never>) in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [
                    NSSortDescriptor(
                        key: #keyPath(PHAsset.creationDate),
                        ascending: false
                    )
                ]
                let result = PHAsset.fetchAssets(with: fetchOptions)
                var allAssets: [PHAsset] = []
                allAssets.reserveCapacity(result.count)
                result.enumerateObjects { asset, index, stop in
                    allAssets.append(asset)
                }
                continuation.resume(returning: allAssets)
            }
            await MainActor.run {
                assets = allAssets
            }
        }
    }

    func fetchThumbnail(for asset: PHAsset, ofSize size: CGSize) async -> UIImage? {
        let scale = UIScreen.main.scale
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

    func toggleAssetSelection(asset: PHAsset) {
        let id = asset.localIdentifier
        if selectedAssetIDs.contains(id) {
            selectedAssetIDs.remove(id)
        } else {
            selectedAssetIDs.insert(id)
        }
    }

    func isSelected(_ asset: PHAsset) -> Bool {
        selectedAssetIDs.contains(asset.localIdentifier)
    }

    func formattedDuration(for asset: PHAsset) -> String {
        Self.durationFormatter.string(from: asset.duration) ?? ""
    }

    func getSelectedAssets() -> [PHAsset] {
        assets.filter { selectedAssetIDs.contains($0.localIdentifier) }
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let fmt = DateComponentsFormatter()
        fmt.allowsFractionalUnits = false
        fmt.allowedUnits = [.second, .minute]
        fmt.zeroFormattingBehavior = .dropTrailing
        return fmt
    }()
}

extension CustomPhotoPickerModel: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task(priority: .userInitiated) {
            await fetchAssets()
        }
    }
}

struct CustomPhotoPicker_Previews: PreviewProvider {
    static var previews: some View {
        CustomPhotoPicker(didFinishPicking: nil)
    }
}

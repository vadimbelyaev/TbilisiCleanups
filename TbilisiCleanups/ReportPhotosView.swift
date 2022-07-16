import SwiftUI
import MapKit
import os.log

struct ReportPhotosView: View {
    @ObservedObject var model: ReportPhotosViewModel
    @State private var isPickerPresented = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 125, maximum: 250),
                        spacing: 0,
                        alignment: .topLeading
                    )
                ],
                alignment: .leading,
                spacing: .zero
            ) {
                ForEach(model.currentDraft.photos) { media in
                    MediaCell(itemProvider: media.itemProvider)
                        .aspectRatio(1, contentMode: .fill)
                }

                Button {
                    isPickerPresented = true
                } label: {
                    Text("Select photos for \(model.currentDraft.placeDescription)")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                }
                .sheet(isPresented: $isPickerPresented) {
                    model.makePhotoPicker(isPresented: $isPickerPresented)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct MediaCell: View {
    private let itemProvider: NSItemProvider
    @State private var image: UIImage? = nil
    @State private var logger = Logger()

    init(itemProvider: NSItemProvider) {
        self.itemProvider = itemProvider
    }

    var body: some View {
        GeometryReader { geometry in
            Color.secondary
                .opacity(0.1)
                .overlay(imageOverlay)
                .clipShape(Rectangle())
                .onAppear {
                    loadThumbnail(for: geometry.frame(in: .local).size)
                }
        }
    }

    @ViewBuilder
    private var imageOverlay: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }

    private func loadThumbnail(for size: CGSize) {
        guard itemProvider.canLoadObject(ofClass: UIImage.self) else {
            logger.error("Error fetching image: item provider can't load a UIImage")
            return
        }

        itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
            guard let fullSizeImage = reading as? UIImage else {
                if let error = error {
                    logger.error("Error fetching image: \(error.localizedDescription, privacy: .public)")
                } else {
                    logger.error("Error fetching image: not a UIImage")
                }
                return
            }
            let fullSize = fullSizeImage.size
            let scale = UIScreen.main.scale
            let maxThumbnailDimension = max(size.width, size.height) * scale
            let aspectRatio = fullSize.height > 0 ? fullSize.width / fullSize.height : 0
            let thumbnailSize = CGSize(
                width: aspectRatio >= 1 ? maxThumbnailDimension * aspectRatio : maxThumbnailDimension,
                height: aspectRatio < 1 ? maxThumbnailDimension * aspectRatio : maxThumbnailDimension
            )
            guard let thumbnail = fullSizeImage.preparingThumbnail(of: thumbnailSize) else {
                logger.error("Error fetching image: could not create a thumbnail")
                return
            }
            DispatchQueue.main.async {
                self.image = thumbnail
            }
        }
    }

    private enum ImageLoadingError: Error {
        case itemProviderCannotLoadUIImage
    }
}

struct ReportPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        ReportPhotosView(model: ReportPhotosViewModel(currentDraft: .constant(.empty)))
    }
}

import SwiftUI
import MapKit

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
                ForEach(model.currentDraft.medias) { media in
                    MediaCell(placeMedia: media)
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
    private let placeMedia: PlaceMedia
    @State private var image: UIImage? = nil

    init(placeMedia: PlaceMedia) {
        self.placeMedia = placeMedia
    }

    var body: some View {
        GeometryReader { geometry in
            Color.secondary
                .opacity(0.1)
                .overlay(imageOverlay)
                .clipShape(Rectangle())
                .task {
                    image = try? await placeMedia.loadThumbnail(for: geometry.frame(in: .local).size)
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
}

struct ReportPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        ReportPhotosView(model: ReportPhotosViewModel(currentDraft: .constant(.empty)))
    }
}

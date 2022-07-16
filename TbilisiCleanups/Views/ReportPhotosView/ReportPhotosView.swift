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
                        spacing: 8,
                        alignment: .topLeading
                    )
                ],
                alignment: .leading,
                spacing: 8
            ) {
                mediaCells
                addPhotosButton
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $isPickerPresented) {
            model.makePhotoPicker(isPresented: $isPickerPresented)
        }
        .navigationTitle("Photos")
    }

    @ViewBuilder
    private var mediaCells: some View {
        ForEach(model.currentDraft.medias) { media in
            MediaCell(placeMedia: media)
                .aspectRatio(1, contentMode: .fill)
                .contextMenu {
                    Button {
                        withAnimation {
                            model.currentDraft.remove(media: media)
                        }
                    } label: {
                        Text("Remove")
                    }
                }
        }
    }

    private var addPhotosButton: some View {
        Button {
            isPickerPresented = true
        } label: {
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.largeTitle)
                    Text("Add photos or videos")
                    Spacer()
                }
                Spacer()
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.selection)
        )
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

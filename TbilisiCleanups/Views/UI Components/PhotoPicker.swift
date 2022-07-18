import PhotosUI
import SwiftUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var results: [PlaceMedia]
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> some UIViewController {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.selectionLimit = 0
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func makeCoordinator() -> PhotoPickerCoordinator {
        PhotoPickerCoordinator(pickerView: self)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // no-op
    }

    final class PhotoPickerCoordinator: PHPickerViewControllerDelegate {
        private let pickerView: PhotoPicker

        init(pickerView: PhotoPicker) {
            self.pickerView = pickerView
        }

        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            let placeMedias = results.map {
                PlaceMedia(
                    assetId: $0.assetIdentifier ?? UUID().uuidString
                )
            }
            pickerView.results.append(contentsOf: placeMedias)
            pickerView.isPresented = false
        }
    }
}

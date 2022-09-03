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
            let placeMedias = results.compactMap { result -> PlaceMedia? in
                guard let assetId = result.assetIdentifier else {
                    AnalyticsService.logEvent(AppError.noAssetIdentifierFromPhotoPicker)
                    return nil
                }
                return PlaceMedia(
                    assetId: assetId
                )
            }
            pickerView.results.append(contentsOf: placeMedias)
            pickerView.isPresented = false
        }
    }
}

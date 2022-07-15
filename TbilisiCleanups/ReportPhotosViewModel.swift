import SwiftUI

final class ReportPhotosViewModel: ObservableObject {
    @Binding var currentDraft: ReportDraft

    init(currentDraft: Binding<ReportDraft>) {
        _currentDraft = currentDraft
    }

    func makePhotoPicker(isPresented: Binding<Bool>) -> some View {
        PhotoPicker(results: $currentDraft.photos, isPresented: isPresented)
    }
}


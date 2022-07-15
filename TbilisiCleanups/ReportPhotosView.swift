import SwiftUI

struct ReportPhotosView: View {
    @ObservedObject var model: ReportPhotosViewModel
    @State private var isPickerPresented = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Button {
            isPickerPresented = true
        } label: {
            Text("Select photos")
        }
        .sheet(isPresented: $isPickerPresented) {
            model.makePhotoPicker(isPresented: $isPickerPresented)
        }
    }
}

struct ReportPhotosView_Previews: PreviewProvider {
    static var previews: some View {
        ReportPhotosView(model: ReportPhotosViewModel(currentDraft: .constant(.empty)))
    }
}

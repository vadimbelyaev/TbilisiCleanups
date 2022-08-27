import SwiftUI
import UIKit

struct UITextViewRepresentable: UIViewRepresentable {
    @Binding var text: String
    @Binding var becomeFocused: Bool
    @Binding var resignFocused: Bool

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.font = .preferredFont(forTextStyle: .body)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        if becomeFocused {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
                    becomeFocused = false
                }
            }
        } else if resignFocused {
            DispatchQueue.main.async {
                uiView.resignFirstResponder()
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
                    resignFocused = false
                }
            }
        }
        uiView.text = text
    }

    func makeCoordinator() -> UITextViewRepresentableCoordinator {
        UITextViewRepresentableCoordinator(text: $text)
    }
}

final class UITextViewRepresentableCoordinator: NSObject {
    @Binding var text: String

    init(text: Binding<String>) {
        self._text = text
    }
}

extension UITextViewRepresentableCoordinator: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        text = textView.text
    }
}

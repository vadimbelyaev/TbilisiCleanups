import SwiftUI

struct OverlayNavigationLink<Destination: View, AuxView: View>: View {
    var title: LocalizedStringKey
    var isDisabled: Bool = false
    var destination: () -> Destination
    @ViewBuilder var auxiliaryView: AuxView

    var body: some View {
        VStack {
            Spacer()
                HStack {
                    Spacer()
                    auxiliaryView
                }
            HStack {
                Spacer()
                NavigationLink(destination: destination) {
                    Text(title)
                        .overlayNavigationLabelStyle()
                }
                .overlayNavigationLinkStyle()
                .disabled(isDisabled)
                .padding(.bottom, 25)
                Spacer()
            }
        }
    }
}

extension View {
    func overlayNavigationLabelStyle() -> some View {
        self
            .frame(maxWidth: 300)
            .padding(.vertical, 8)
    }

    func overlayNavigationLinkStyle() -> some View {
        buttonStyle(.borderedProminent)
    }
}

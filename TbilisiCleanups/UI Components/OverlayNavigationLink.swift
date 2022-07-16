import SwiftUI

struct OverlayNavigationLink<Destination: View, AuxView: View>: View {
    var title: LocalizedStringKey
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
                        .frame(maxWidth: 300)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 25)
                Spacer()
            }
        }
    }
}

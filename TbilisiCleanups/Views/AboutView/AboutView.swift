import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationView {
            List {
                Section(L10n.About.whatIsNogarbage) {
                    Text(L10n.About.aboutNogarbage)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical)
                    socialButton(for: .website, withText: L10n.About.ourWebsite)
                }

                Section(L10n.About.social) {
                    socialButton(for: .facebook, withText: L10n.About.facebook)
                    socialButton(for: .instagram, withText: L10n.About.instagram)
                    socialButton(for: .telegramChannel, withText: L10n.About.telegramChannel)
                    socialButton(for: .telegramChat, withText: L10n.About.telegramChat)
                }
            }
            .navigationTitle(L10n.About.title)
        }
        .navigationViewStyle(.stack)
        .tabItem {
            Image(systemName: "info")
            Text(L10n.About.tabName)
        }
    }

    private func socialButton(
        for socialURL: SocialURL,
        withText text: String
    ) -> some View {
        Button {
            openSocialURL(socialURL)
        } label: {
            Label {
                Text(text)
            } icon: {
                socialURL.image
                    .resizable()
                    .frame(width: 28, height: 28)
            }
        }
    }

    private func openSocialURL(_ socialURL: SocialURL) {
        guard let url = URL(string: socialURL.rawValue),
              UIApplication.shared.canOpenURL(url)
        else { return }
        UIApplication.shared.open(url)
    }
}

private enum SocialURL: String {
    case website = "https://nogarba.ge"
    case facebook = "https://www.facebook.com/tbilisicleanups"
    case instagram = "https://instagram.com/tbilisi_clean_ups"
    case telegramChannel = "https://t.me/tbilisicleanups"
    case telegramChat = "https://t.me/tbilisi_cleanups"

    var image: Image {
        switch self {
        case .website:
            return Image(systemName: "globe")
        case .facebook:
            return Asset.Social.facebook.swiftUIImage
        case .instagram:
            return Asset.Social.instagram.swiftUIImage
        case .telegramChannel, .telegramChat:
            return Asset.Social.telegram.swiftUIImage
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

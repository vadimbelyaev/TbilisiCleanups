import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationView {
            List {
                Section("What is nogarba.ge") {
                    Text(
                        """
                        **nogarba.ge** is a volunteer eco initiative in \
                        the country of Georgia 🇬🇪. We get together to clean up \
                        public parks and recreation zones.

                        Be a part of the solution, not the problem!
                        """
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical)
                    socialButton(for: .website, withText: "Our website nogarba.ge")
                }

                Section("Social") {
                    socialButton(for: .facebook, withText: "Facebook")
                    socialButton(for: .instagram, withText: "Instagram")
                    socialButton(for: .telegramChannel, withText: "Telegram channel")
                    socialButton(for: .telegramChat, withText: "Telegram chat")
                }
            }
            .navigationTitle("About")
        }
        .navigationViewStyle(.stack)
        .tabItem {
            Image(systemName: "info")
            Text("About")
        }
    }

    private func socialButton(
        for socialURL: SocialURL,
        withText text: LocalizedStringKey
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
            return Image("Social/Facebook")
        case .instagram:
            return Image("Social/Instagram")
        case .telegramChannel, .telegramChat:
            return Image("Social/Telegram")
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

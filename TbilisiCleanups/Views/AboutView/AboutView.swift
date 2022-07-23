//
//  AboutView.swift
//  TbilisiCleanups
//
//  Created by Vadim Belyaev on 23.07.2022.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationView {
            List {
                Section("What is Tbilisi Clean-ups") {
                    Text("Tbilisi Clean-ups is a volunteer eco initiative in the country of Georgia 🇬🇪. We get together to clean up public parks and recreation zones.\n\nBe a part of the solution, not the problem!")
                    Button {
                        openSocialURL(.website)
                    } label: {
                        Label {
                            Text("Our website nogarba.ge")
                        } icon: {
                            Image(systemName: "globe")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }

                    }
                }

                Section("Social") {
                    Button {
                        openSocialURL(.facebook)
                    } label: {
                        Label {
                            Text("Facebook")
                        } icon: {
                            Image("Social/Facebook")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }

                    }

                    Button {
                        openSocialURL(.instagram)
                    } label: {
                        Label {
                            Text("Instagram")
                        } icon: {
                            Image("Social/Instagram")
                                .resizable()
                                .frame(width: 28, height: 28)
                        }

                    }
                }
            }
            .navigationTitle("About")
        }
        .tabItem {
            Image(systemName: "info")
            Text("About")
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
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}

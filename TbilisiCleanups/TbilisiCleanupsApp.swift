import Firebase
import SwiftUI

@main
struct TbilisiCleanupsApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

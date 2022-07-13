//
//  TbilisiCleanupsApp.swift
//  TbilisiCleanups
//
//  Created by Vadim Belyaev on 14.07.2022.
//

import Firebase
import SwiftUI

@main
struct TbilisiCleanupsApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

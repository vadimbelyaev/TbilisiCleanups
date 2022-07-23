//
//  StateRestorationService.swift
//  TbilisiCleanups
//
//  Created by Vadim Belyaev on 23.07.2022.
//

import Foundation

@MainActor
final class StateRestorationService {
    private let appState: AppState
    private let userDefaults = UserDefaults.standard

    init(appState: AppState) {
        self.appState = appState
    }

    func saveState() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(appState.currentDraft)
        userDefaults.set(data, forKey: "currentDraft")
        print("SAVED STATE with \(appState.currentDraft.medias.count) MEDIAS")
    }

    func restoreState() throws {
        guard let data = userDefaults.object(forKey: "currentDraft") as? Data
        else { return }
        let decoder = JSONDecoder()
        let draft = try decoder.decode(ReportDraft.self, from: data)
        appState.currentDraft = draft
        print("RESTORED STATE with \(draft.medias.count) MEDIAS")
    }
}

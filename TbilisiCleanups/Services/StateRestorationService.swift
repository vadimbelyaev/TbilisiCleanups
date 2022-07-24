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
    }

    func restoreState() throws {
        guard let data = userDefaults.object(forKey: "currentDraft") as? Data
        else { return }
        let decoder = JSONDecoder()
        let draft = try decoder.decode(ReportDraft.self, from: data)
        appState.currentDraft = draft
    }
}

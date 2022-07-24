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

    func eraseDraftState() {
        userDefaults.set(nil, forKey: "currentDraft")
    }

    func restoreState() throws {
        guard let data = userDefaults.object(forKey: "currentDraft") as? Data
        else { return }
        let decoder = JSONDecoder()
        var draft = try decoder.decode(ReportDraft.self, from: data)

        // Forcefully changing the draft ID so that it doesn't accidentally get
        // submitted with a duplicate ID, say, after a crash
        draft.id = UUID()

        appState.currentDraft = draft
    }
}

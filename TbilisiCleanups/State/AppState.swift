import Foundation

@MainActor
final class AppState: ObservableObject {
    var currentDraft: ReportDraft = .init()
    var userState: UserState = .init()
}


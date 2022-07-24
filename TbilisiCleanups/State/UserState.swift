import Foundation

@MainActor
final class UserState: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: String?
    @Published var userProviderId: String?
    @Published var userName: String?
}

import Foundation

@MainActor
final class UserState: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: String? = nil
    @Published var userProviderId: String? = nil
    @Published var userName: String? = nil
}

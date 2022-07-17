import Foundation

final class UserState: ObservableObject {
    @Published var isAuthenticated: Bool = false
}

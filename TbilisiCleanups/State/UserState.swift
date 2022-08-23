import Combine
import Foundation

@MainActor
final class UserState: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: String?
    @Published var userProviderId: String?
    @Published var userName: String?

    // Do not modify this property directly. Instead, send the new value through
    // the updateReportStateChangeNotificationsPreference subject.
    // That will ensure that the preference is saved to Firebase.
    @Published var reportStateChangeNotificationsEnabled: Bool = false
    let updateReportStateChangeNotificationsPreference = PassthroughSubject<Bool, Never>()
}

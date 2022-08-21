import SwiftUI
import UIKit

extension Report.Status {
    var uiColor: UIColor {
        switch self {
        case .rejected:
            return .systemGray
        case .clean:
            return .systemGreen
        case .dirty:
            return .systemRed
        case .scheduled:
            return .systemPurple
        case .moderation:
            return .systemBlue
        case .unknown:
            return .systemGray
        }
    }

    var swiftUIColor: SwiftUI.Color {
        switch self {
        case .unknown:
            return .gray
        case .rejected:
            return .gray
        case .scheduled:
            return .purple
        case .dirty:
            return .red
        case .clean:
            return .green
        case .moderation:
            return .blue
        }
    }
}

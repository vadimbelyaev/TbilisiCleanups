import SwiftUI
import UIKit

extension Report.Status {
    var uiColor: UIColor {
        switch self {
        case .rejected:
            return .systemMint
        case .clean:
            return .systemGreen
        case .dirty:
            return .systemGray
        case .scheduled:
            return .systemRed
        case .moderation:
            return .systemBlue
        case .unknown:
            return .systemMint
        }
    }

    var swiftUIColor: SwiftUI.Color {
        switch self {
        case .unknown:
            return .mint
        case .rejected:
            return .mint
        case .scheduled:
            return .red
        case .dirty:
            return .gray
        case .clean:
            return .green
        case .moderation:
            return .blue
        }
    }
}

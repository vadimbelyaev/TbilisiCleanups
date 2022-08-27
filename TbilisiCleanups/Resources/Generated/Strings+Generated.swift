// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum About {
    /// nogarba.ge is a volunteer eco initiative in the country of Georgia 🇬🇪. We get together to clean up public parks and recreation zones.
    /// 
    /// Be a part of the solution, not the problem!
    internal static let aboutNogarbage = L10n.tr("Localizable", "About.aboutNogarbage", fallback: #"nogarba.ge is a volunteer eco initiative in the country of Georgia 🇬🇪. We get together to clean up public parks and recreation zones.\n\nBe a part of the solution, not the problem!"#)
    /// Facebook
    internal static let facebook = L10n.tr("Localizable", "About.facebook", fallback: #"Facebook"#)
    /// Instagram
    internal static let instagram = L10n.tr("Localizable", "About.instagram", fallback: #"Instagram"#)
    /// Our Website nogarba.ge
    internal static let ourWebsite = L10n.tr("Localizable", "About.ourWebsite", fallback: #"Our Website nogarba.ge"#)
    /// Social
    internal static let social = L10n.tr("Localizable", "About.social", fallback: #"Social"#)
    /// About
    internal static let tabName = L10n.tr("Localizable", "About.tabName", fallback: #"About"#)
    /// Telegram Channel
    internal static let telegramChannel = L10n.tr("Localizable", "About.telegramChannel", fallback: #"Telegram Channel"#)
    /// Telegram Chat
    internal static let telegramChat = L10n.tr("Localizable", "About.telegramChat", fallback: #"Telegram Chat"#)
    /// About
    internal static let title = L10n.tr("Localizable", "About.title", fallback: #"About"#)
    /// What Is nogarba.ge
    internal static let whatIsNogarbage = L10n.tr("Localizable", "About.whatIsNogarbage", fallback: #"What Is nogarba.ge"#)
  }
  internal enum UserProfile {
    /// Account
    internal static let accountSection = L10n.tr("Localizable", "UserProfile.accountSection", fallback: #"Account"#)
    /// Allow Notifications
    internal static let allowNotifications = L10n.tr("Localizable", "UserProfile.allowNotifications", fallback: #"Allow Notifications"#)
    /// Contributions
    internal static let contributionsSection = L10n.tr("Localizable", "UserProfile.contributionsSection", fallback: #"Contributions"#)
    /// Delete My Account
    internal static let deleteMyAccount = L10n.tr("Localizable", "UserProfile.deleteMyAccount", fallback: #"Delete My Account"#)
    /// There was an error deleting your account. Please try again later.
    internal static let errorDeletingAccount = L10n.tr("Localizable", "UserProfile.errorDeletingAccount", fallback: #"There was an error deleting your account. Please try again later."#)
    /// My Reports
    internal static let myReports = L10n.tr("Localizable", "UserProfile.myReports", fallback: #"My Reports"#)
    /// My Profile
    internal static let nonameTitle = L10n.tr("Localizable", "UserProfile.nonameTitle", fallback: #"My Profile"#)
    /// Notifications
    internal static let notificationsSection = L10n.tr("Localizable", "UserProfile.notificationsSection", fallback: #"Notifications"#)
    /// Sign Out
    internal static let signOutButton = L10n.tr("Localizable", "UserProfile.signOutButton", fallback: #"Sign Out"#)
    /// Statuses Of My Reports
    internal static let statusesOfMyReports = L10n.tr("Localizable", "UserProfile.statusesOfMyReports", fallback: #"Statuses Of My Reports"#)
    /// My Profile
    internal static let tabName = L10n.tr("Localizable", "UserProfile.tabName", fallback: #"My Profile"#)
    internal enum DeleteAccountConfirmation {
      /// Delete My Account
      internal static let deleteAction = L10n.tr("Localizable", "UserProfile.DeleteAccountConfirmation.deleteAction", fallback: #"Delete My Account"#)
      /// Do Not Delete
      internal static let doNotDeleteAction = L10n.tr("Localizable", "UserProfile.DeleteAccountConfirmation.doNotDeleteAction", fallback: #"Do Not Delete"#)
      /// Delete your account? This action cannot be undone.
      internal static let title = L10n.tr("Localizable", "UserProfile.DeleteAccountConfirmation.title", fallback: #"Delete your account? This action cannot be undone."#)
    }
    internal enum Guest {
      /// Manage your account, see your reports and their statuses.
      internal static let body = L10n.tr("Localizable", "UserProfile.Guest.body", fallback: #"Manage your account, see your reports and their statuses."#)
      /// Sign In
      internal static let signInButton = L10n.tr("Localizable", "UserProfile.Guest.signInButton", fallback: #"Sign In"#)
      /// Sign In
      internal static let title = L10n.tr("Localizable", "UserProfile.Guest.title", fallback: #"Sign In"#)
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type

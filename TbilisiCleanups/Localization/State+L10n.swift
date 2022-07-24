//
//  State+L10n.swift
//  TbilisiCleanups
//
//  Created by Vadim Belyaev on 21.07.2022.
//

import Foundation

extension Report.Status {
    var localizedDescription: String {
        switch self {
        case .moderation:
            return NSLocalizedString(
                "Moderation",
                comment: "Report status - under moderation"
            )
        case .dirty:
            return NSLocalizedString(
                "Dirty",
                comment: "Report status - dirty"
            )
        case .scheduled:
            return NSLocalizedString(
                "Scheduled",
                comment: "Report status - cleanup is scheduled for this place"
            )
        case .clean:
            return NSLocalizedString(
                "Clean",
                comment: "Report status - clean"
            )
        case .rejected:
            return NSLocalizedString(
                "Rejected",
                comment: "Report status - did not pass moderation"
            )
        case .unknown:
            return NSLocalizedString(
                "Unknown",
                comment: "Report status - unknown"
            )
        }
    }
}

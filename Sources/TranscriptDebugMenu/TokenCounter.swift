//
//  Created by Artem Novichkov on 17.02.2026.
//

import SwiftUI

enum TokenCounter {
    static func formattedCount(for usage: (tokenCount: Int, contextSize: Int)) -> LocalizedStringKey {
        let percent = usage.contextSize > 0 ? Float(usage.tokenCount) / Float(usage.contextSize) : 0
        let formattedPercent = percent.formatted(.percent.precision(.fractionLength(1)).rounded(rule: .down))
        return "\(usage.tokenCount)/^[\(usage.contextSize) token](inflect: true) (\(formattedPercent) of context size)"
    }
}

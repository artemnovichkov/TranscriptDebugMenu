//
//  Created by Artem Novichkov on 17.02.2026.
//

import Foundation
import FoundationModels

@available(iOS 26.4, macOS 26.4, macCatalyst 26.4, visionOS 26.4, *)
extension SystemLanguageModel.TokenUsage {
    func percent(ofContextSize contextSize: Int) -> Float {
        guard contextSize > 0 else { return 0 }
        return Float(tokenCount) / Float(contextSize)
    }

    func formattedPercent(ofContextSize contextSize: Int) -> String {
        percent(ofContextSize: contextSize)
            .formatted(.percent.precision(.fractionLength(1)).rounded(rule: .down))
    }
}

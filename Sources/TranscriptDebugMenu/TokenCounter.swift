//
//  Created by Artem Novichkov on 17.02.2026.
//

import FoundationModels
import OSLog
import SwiftUI

enum TokenCounter {
    private static let logger = Logger(
        subsystem: "com.artemnovichkov.TranscriptDebugMenu",
        category: "TokenCounter"
    )

    static func formattedCount(for entries: some Collection<Transcript.Entry>, model: SystemLanguageModel = .default) async -> LocalizedStringKey? {
        guard #available(iOS 26.4, macOS 26.4, macCatalyst 26.4, visionOS 26.4, *) else {
            return nil
        }
        do {
            let tokenCount = try await model.tokenCount(for: entries)
            let contextSize = model.contextSize
            let percent = contextSize > 0 ? Float(tokenCount) / Float(contextSize) : 0
            let formattedPercent = percent.formatted(.percent.precision(.fractionLength(1)).rounded(rule: .down))
            return "^[\(tokenCount) token](inflect: true) (\(formattedPercent) of context size)"
        } catch {
            logger.error("Failed to get token usage: \(error.localizedDescription)")
            return nil
        }
    }
}

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

    static func contextUsage(for entries: some Collection<Transcript.Entry>, model: SystemLanguageModel = .default) async -> (tokenCount: Int, contextSize: Int)? {
        guard #available(iOS 26.4, macOS 26.4, macCatalyst 26.4, visionOS 26.4, *) else {
            return nil
        }
        do {
            let tokenCount = try await model.tokenCount(for: entries)
            return (tokenCount, model.contextSize)
        } catch {
            logger.error("Failed to get token usage: \(error.localizedDescription)")
            return nil
        }
    }

    static func formattedCount(for entries: some Collection<Transcript.Entry>, model: SystemLanguageModel = .default) async -> LocalizedStringKey? {
        guard let usage = await contextUsage(for: entries, model: model) else {
            return nil
        }
        return formattedCount(for: usage)
    }

    static func formattedCount(for usage: (tokenCount: Int, contextSize: Int)) -> LocalizedStringKey {
        let percent = usage.contextSize > 0 ? Float(usage.tokenCount) / Float(usage.contextSize) : 0
        let formattedPercent = percent.formatted(.percent.precision(.fractionLength(1)).rounded(rule: .down))
        return "\(usage.tokenCount)/^[\(usage.contextSize) token](inflect: true) (\(formattedPercent) of context size)"
    }
}

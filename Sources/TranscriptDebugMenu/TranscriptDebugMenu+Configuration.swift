//
//  Created by Artem Novichkov on 04.09.2026.
//

import Foundation
import FoundationModels

public extension TranscriptDebugMenu {
    /// Configuration for the transcript debug menu.
    struct Configuration: Sendable {
        /// A provider that calculates model-specific context-window metrics.
        public var contextMetricsProvider: ContextMetricsProvider?

        /// Creates a configuration.
        ///
        /// Pass `nil` when the session's model doesn't expose a compatible token counter.
        public init(contextMetricsProvider: ContextMetricsProvider? = nil) {
            self.contextMetricsProvider = contextMetricsProvider
        }

        /// Creates a configuration for a system language model.
        public static func systemModel(_ model: SystemLanguageModel) -> Self {
            Self(contextMetricsProvider: .systemModel(model))
        }
    }

    /// Token consumption relative to a model's context window.
    struct ContextMetrics: Sendable, Equatable {
        public let tokenCount: Int
        public let contextSize: Int

        public init(tokenCount: Int, contextSize: Int) {
            self.tokenCount = tokenCount
            self.contextSize = contextSize
        }

        var isValid: Bool {
            tokenCount >= 0 && contextSize > 0
        }
    }

    /// Calculates context-window metrics for a transcript.
    ///
    /// The menu supplies either the complete transcript or a transcript containing
    /// a single entry for its detail view. Keep custom providers stable across view updates.
    struct ContextMetricsProvider: Sendable {
        var id: ContextMetricsProviderID = .custom(UUID())
        private let calculate: @Sendable (Transcript) async throws -> ContextMetrics

        public init(
            calculate: @escaping @Sendable (Transcript) async throws -> ContextMetrics
        ) {
            self.calculate = calculate
        }

        /// Creates a provider backed by a system language model's tokenizer.
        public static func systemModel(_ model: SystemLanguageModel) -> Self {
            var provider = Self { transcript in
                guard #available(iOS 26.4, macOS 26.4, macCatalyst 26.4, visionOS 26.4, *) else {
                    throw ContextMetricsUnavailableError()
                }
                let tokenCount = try await model.tokenCount(for: transcript)
                return ContextMetrics(tokenCount: tokenCount, contextSize: model.contextSize)
            }
            provider.id = .systemModel(ObjectIdentifier(model))
            return provider
        }

        func metrics(for transcript: Transcript) async throws -> ContextMetrics {
            try await calculate(transcript)
        }
    }
}

/// Restarts diagnostics when either the transcript or its configured counter changes.
struct ContextMetricsRequest: Equatable {
    let transcript: Transcript
    let providerID: ContextMetricsProviderID?
}

enum ContextMetricsProviderID: Sendable, Equatable {
    case custom(UUID)
    case systemModel(ObjectIdentifier)
}

private struct ContextMetricsUnavailableError: Error {}

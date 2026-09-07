//
//  Created by Artem Novichkov on 04.08.2025.
//

import Foundation
import SwiftUI
import FoundationModels
import OSLog

/// A SwiftUI view for inspecting, copying, and capturing feedback for `LanguageModelSession` transcripts.
///
/// `TranscriptDebugMenu` shows searchable transcript entries, detailed Foundation Models metadata,
/// context-window metrics, full transcript export, and a feedback composer that produces a
/// `LanguageModelFeedback` JSON file for [Feedback Assistant](https://feedbackassistant.apple.com/).
///
/// ## Usage
///
/// ```swift
/// import SwiftUI
/// import FoundationModels
/// import TranscriptDebugMenu
///
/// struct ContentView: View {
///    @State private var showTranscript = false
///    private static let model = SystemLanguageModel.default
///    @State private var session = LanguageModelSession(model: ContentView.model)
///
///    var body: some View {
///        VStack {
///            Button("Show Transcript Menu") {
///                showTranscript = true
///            }
///        }
///        .transcriptDebugMenu(
///            session,
///            isPresented: $showTranscript,
///            configuration: .systemModel(Self.model)
///        )
///    }
///}
/// ```
public struct TranscriptDebugMenu: View {
    private let session: LanguageModelSession
    private let configuration: Configuration

    @State private var feedbackFileURL: URL = FileManager.default
        .temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("feedback")
        .appendingPathExtension("json")
    @State private var transcriptFileURL: URL = FileManager.default
        .temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("transcript")
        .appendingPathExtension("json")

    @State private var feedbackDraft = FeedbackDraft()
    @State private var isFeedbackPresented = false
    @State private var feedbackDataFileSaved = false
    @State private var transcriptDataFileSaved = false
    private let logger = Logger(
        subsystem: "com.artemnovichkov.TranscriptDebugMenu",
        category: "TranscriptDebugMenu"
    )
    @State private var contextUsage: ContextMetrics?
    @State private var searchText: String = ""
    @State private var searchScope: SearchScope = .all
    @State private var path: [EntryRoute] = []

    /// Creates a new transcript debug menu for the specified session.
    ///
    /// - Parameters:
    ///   - session: The `LanguageModelSession` whose transcript will be displayed.
    ///   - configuration: Model-specific context metrics and future menu customization.
    ///     Defaults to an empty configuration, which omits context metrics without assuming a model.
    public init(session: LanguageModelSession, configuration: Configuration = .init()) {
        self.session = session
        self.configuration = configuration
    }

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                contextSection
                usageSection
                errorPolicySection
                if !filteredTranscript.isEmpty {
                    TranscriptSection(
                        transcript: filteredTranscript,
                        onSelect: { path.append(EntryRoute(id: $0.id)) },
                        onCopy: copyToClipboard
                    )
                }
                if session.isResponding {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .overlay {
                if session.transcript.isEmpty && !session.isResponding {
                    ContentUnavailableView("No entries",
                                           systemImage: "apple.intelligence",
                                           description: Text("The transcript is empty"))
                } else if !searchText.isEmpty && filteredTranscript.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("Transcript")
            .navigationDestination(for: EntryRoute.self) { route in
                if let entry = session.transcript.first(where: { $0.id == route.id }) {
                    TranscriptEntryDetailView(
                        entry: entry,
                        contextMetricsProvider: configuration.contextMetricsProvider
                    )
                } else {
                    ContentUnavailableView(
                        "Entry Unavailable",
                        systemImage: "doc.questionmark",
                        description: Text("The entry was removed from the session transcript.")
                    )
                }
            }
            .toolbar {
                toolbar
            }
            .onAppear {
                saveTranscriptExport()
                saveFeedbackAttachment()
            }
            .onChange(of: session.transcript) {
                saveTranscriptExport()
                saveFeedbackAttachment()
            }
            .task(id: ContextMetricsRequest(
                transcript: session.transcript,
                providerID: configuration.contextMetricsProvider?.id
            )) {
                await refreshContextUsage()
            }
            .onChange(of: feedbackDraft) {
                saveFeedbackAttachment()
            }
            .searchable(text: $searchText)
            .searchScopes($searchScope, activation: .onSearchPresentation) {
                ForEach(SearchScope.allCases) { scope in
                    Text(scope.title)
                        .tag(scope)
                }
            }
            .animation(.easeInOut, value: session.transcript)
            .sheet(isPresented: $isFeedbackPresented) {
                FeedbackView(
                    draft: $feedbackDraft,
                    attachmentURL: feedbackDataFileSaved ? feedbackFileURL : nil,
                    onRetry: saveFeedbackAttachment
                )
            }
        }
        .onDisappear {
            removeTemporaryExports()
        }
    }

    // MARK: - Private

    @ViewBuilder
    private var contextSection: some View {
        if let contextUsage, searchText.isEmpty {
            ContextSection(tokenCount: contextUsage.tokenCount,
                           contextSize: contextUsage.contextSize)
        }
    }

    @ViewBuilder
    private var errorPolicySection: some View {
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *),
           searchText.isEmpty, !session.transcript.isEmpty,
           let policy = session.transcriptErrorHandlingPolicy {
            Section("Session") {
                DebugValueRow("Error Policy", value: String(describing: policy))
            }
        }
    }

    @ViewBuilder
    private var usageSection: some View {
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *),
           searchText.isEmpty, !session.transcript.isEmpty {
            UsageSection(usage: session.usage)
        }
    }

    private var filteredTranscript: Transcript {
        TranscriptFilter.filter(session.transcript, searchText: searchText, scope: searchScope)
    }

    @ContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem {
            Menu("Export", systemImage: "square.and.arrow.up") {
                Button("Copy Transcript JSON", systemImage: "document.on.document") {
                    DebugClipboard.copy(DebugJSON.prettyPrinted(session.transcript))
                }
                if transcriptDataFileSaved {
                    ShareLink(item: transcriptFileURL) {
                        Label("Share Transcript JSON", systemImage: "square.and.arrow.up")
                    }
                }
                Divider()
                Button("Report Feedback…", systemImage: "bubble.and.pencil") {
                    saveFeedbackAttachment()
                    isFeedbackPresented = true
                }
            }
        }
    }

    @MainActor
    private func refreshContextUsage() async {
        contextUsage = nil
        guard let provider = configuration.contextMetricsProvider else {
            contextUsage = nil
            return
        }
        do {
            let metrics = try await provider.metrics(for: session.transcript)
            try Task.checkCancellation()
            guard metrics.isValid else {
                contextUsage = nil
                logger.error("Context metrics must use a nonnegative token count and a positive context size.")
                return
            }
            contextUsage = metrics
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            contextUsage = nil
            logger.error("Failed to get context metrics: \(error.localizedDescription)")
        }
    }

    private func saveFeedbackAttachment() {
        let feedbackData = session.logFeedbackAttachment(
            sentiment: feedbackDraft.sentiment.value,
            issues: feedbackDraft.issues,
            desiredResponseText: feedbackDraft.desiredResponse
        )
        do {
            try feedbackData.write(to: feedbackFileURL, options: .atomic)
            feedbackDataFileSaved = true
        } catch {
            feedbackDataFileSaved = false
            logger.error("Failed to save feedback attachment: \(error.localizedDescription)")
        }
    }

    private func saveTranscriptExport() {
        guard let data = DebugJSON.prettyPrinted(session.transcript).data(using: .utf8) else {
            transcriptDataFileSaved = false
            return
        }
        do {
            try data.write(to: transcriptFileURL, options: .atomic)
            transcriptDataFileSaved = true
        } catch {
            transcriptDataFileSaved = false
            logger.error("Failed to save transcript: \(error.localizedDescription)")
        }
    }

    private func removeTemporaryExports() {
        try? FileManager.default.removeItem(at: feedbackFileURL)
        try? FileManager.default.removeItem(at: transcriptFileURL)
        feedbackDataFileSaved = false
        transcriptDataFileSaved = false
    }

    private func copyToClipboard(entry: Transcript.Entry) {
        DebugClipboard.copy(entry.description)
    }
}

private struct EntryRoute: Hashable {
    let id: String
}

#Preview {
    @Previewable @State var isPresented = true
    @Previewable @State var session = LanguageModelSession(transcript: .mock)

    Button("Show Transcript Menu") {
        isPresented.toggle()
    }
    .transcriptDebugMenu(
        session,
        isPresented: $isPresented,
        configuration: .systemModel(.default)
    )
}

#Preview("Transcript") {
    TranscriptDebugMenu(
        session: LanguageModelSession(transcript: .mock),
        configuration: .init(contextMetricsProvider: .init { _ in
            .init(tokenCount: Mock.contextUsage.tokenCount, contextSize: Mock.contextUsage.contextSize)
        })
    )
}

#Preview("Empty Transcript") {
    TranscriptDebugMenu(session: LanguageModelSession(transcript: Transcript()))
}

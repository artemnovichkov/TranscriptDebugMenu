//
//  Created by Artem Novichkov on 04.08.2025.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI
import FoundationModels
import OSLog

/// A SwiftUI view for inspecting, copying, and capturing feedback for `LanguageModelSession` transcripts.
///
/// `TranscriptDebugMenu` shows transcript entries in a list with a context menu to copy any entry.
/// It also lets you mark the conversation sentiment and automatically
/// generates a `LanguageModelFeedback` JSON file that can be submitted to Apple using [Feedback Assistant](https://feedbackassistant.apple.com/).
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
///    @State private var session = LanguageModelSession()
///
///    var body: some View {
///        VStack {
///            Button("Show Transcript Menu") {
///                showTranscript = true
///            }
///        }
///        .transcriptDebugMenu(session, isPresented: $showTranscript)
///    }
///}
/// ```
public struct TranscriptDebugMenu: View {
    /// The language model session containing the transcript to display.
    let session: LanguageModelSession

    private let feedbackFileURL: URL = FileManager.default
        .temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")

    @State private var sentiment: LanguageModelFeedback.Sentiment?
    @State private var feedbackDataFileSaved: Bool = false
    private let logger = Logger(subsystem: "com.artemnovichkov.TranscriptDebugMenu", category: "TranscriptDebugMenu")
    @State private var searchText: String = ""
    @State private var searchScope: SearchScope = .all
    @State private var path = NavigationPath()

    /// Creates a new transcript debug menu for the specified session.
    ///
    /// - Parameter session: The `LanguageModelSession` whose transcript will be displayed.
    ///   The session's transcript property is used to populate the list of entries.
    public init(session: LanguageModelSession) {
        self.session = session
    }

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(entries) { entry in
                    Text(entry.description)
                        .transition(.opacity)
                        .onTapGesture {
                            path.append(entry)
                        }
                        .contextMenu {
                            Button("Copy") {
                                copyToClipboard(entry: entry)
                            }
                        }
                }
                if session.isResponding {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .animation(.easeInOut, value: session.transcript)
            .overlay {
                if session.transcript.isEmpty {
                    ContentUnavailableView("No entries",
                                           systemImage: "apple.intelligence",
                                           description: Text("The transcript is empty"))

                }
            }
            .navigationTitle("Transcript")
            .navigationDestination(for: Transcript.Entry.self) { entry in
                TranscriptEntryDetailView(entry: entry)
            }
            .toolbar {
                toolbar
            }
            .onAppear {
                saveFeedbackAttachment(sentiment: sentiment)
            }
            .onChange(of: sentiment) { _, newValue in
                saveFeedbackAttachment(sentiment: newValue)
            }
            .searchable(text: $searchText)
            .searchScopes($searchScope, activation: .onSearchPresentation) {
                ForEach(SearchScope.allCases) { scope in
                    Text(scope.title)
                        .tag(scope)
                }
            }
        }
    }

    // MARK: - Private
    
    private var entries: [Transcript.Entry] {
        if searchText.isEmpty {
            return Array(session.transcript)
        }
        return session.transcript
            .filter { entry in
                switch searchScope {
                case .all:
                    return true
                case .instructions:
                    if case .instructions = entry { return true }
                    return false
                case .prompt:
                    if case .prompt = entry { return true }
                    return false
                case .toolCalls:
                    if case .toolCalls = entry { return true }
                    return false
                case .toolOutput:
                    if case .toolOutput = entry { return true }
                    return false
                case .response:
                    if case .response = entry { return true }
                    return false
                }
            }
            .filter { entry in
                entry.description.localizedCaseInsensitiveContains(searchText)
            }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem {
            Button {
                sentiment = sentiment == .negative ? nil : .negative
            } label: {
                Label("Negative",
                      systemImage: "hand.thumbsdown" + (sentiment == .negative ? ".fill" : ""))
            }
        }
        ToolbarItem {
            Button {
                sentiment = sentiment == .positive ? nil : .positive
            } label: {
                Label("Positive",
                      systemImage: "hand.thumbsup" + (sentiment == .positive ? ".fill" : "" ))
            }
        }
        ToolbarSpacer()
        ToolbarItem {
            ShareLink(item: feedbackFileURL)
                .disabled(!feedbackDataFileSaved)
        }
    }

    private func saveFeedbackAttachment(sentiment: LanguageModelFeedback.Sentiment?) {
        let feedbackData = session.logFeedbackAttachment(sentiment: sentiment)
        do {
            try feedbackData.write(to: feedbackFileURL)
            feedbackDataFileSaved = true
        } catch {
            feedbackDataFileSaved = false
            logger.error("Failed to save feedback attachment: \(error.localizedDescription)")
        }
    }

    private func copyToClipboard(entry: Transcript.Entry) {
        #if canImport(UIKit)
        UIPasteboard.general.string = entry.description
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.description, forType: .string)
        #endif
    }
}

extension Transcript.Entry: @retroactive Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    @Previewable @State var isPresented = false
    @Previewable @State var session = LanguageModelSession(transcript: .mock)

    Button("Show Transcript Menu") {
        isPresented.toggle()
    }
    .transcriptDebugMenu(session, isPresented: $isPresented)
}

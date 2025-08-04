//
//  Created by Artem Novichkov on 04.08.2025.
//

import SwiftUI
import FoundationModels

/// A SwiftUI view that displays a debug menu for viewing and copying `LanguageModelSession` transcripts.
///
/// `TranscriptDebugMenu` provides a list interface for inspecting
/// language model session transcripts. Each transcript entry can be viewed and copied to the
/// clipboard using a context menu.
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

    /// Creates a new transcript debug menu for the specified session.
    ///
    /// - Parameter session: The `LanguageModelSession` whose transcript will be displayed.
    ///   The session's transcript property is used to populate the list of entries.
    public init(session: LanguageModelSession) {
        self.session = session
    }

    public var body: some View {
        NavigationStack {
            List {
                ForEach(session.transcript) { entry in
                    Text(entry.description)
                        .contextMenu {
                            Button("Copy") {
                                UIPasteboard.general.string = entry.description
                            }
                        }
                }
            }
            .overlay {
                if session.transcript.isEmpty {
                    ContentUnavailableView("No entries", systemImage: "apple.intelligence", description: Text("The transcript is empty"))

                }
            }
            .navigationTitle("Transcript")
        }
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

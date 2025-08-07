import SwiftUI
import FoundationModels
import TranscriptDebugMenu

struct ContentView: View {
    @State private var text = "Loading..."
    @State private var session = LanguageModelSession()
    @State private var showTranscript = false

    var body: some View {
        NavigationStack {
            VStack {
                Text(text)
            }
            .padding(.horizontal)
            .navigationTitle("Haiku")
            .transcriptDebugMenu(session, isPresented: $showTranscript)
            .toolbar {
                ToolbarItem {
                    Button {
                        showTranscript.toggle()
                    } label: {
                        Label("Transcript", systemImage: "gear")
                    }
                }
            }
            .task {
                do {
                    let response = try await session.respond(to: "Generate a haiku about Swift")
                    text = response.content
                } catch {
                    print("Error: \(error)")
                }
            }
        }
    }
}

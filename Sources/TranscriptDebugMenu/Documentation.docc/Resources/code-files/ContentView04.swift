import SwiftUI
import FoundationModels
import TranscriptDebugMenu

struct ContentView: View {
    @State private var text = "Loading..."
    private static let model = SystemLanguageModel.default
    @State private var session = LanguageModelSession(model: ContentView.model)
    @State private var showTranscript = false

    var body: some View {
        NavigationStack {
            VStack {
                Text(text)
            }
            .padding(.horizontal)
            .navigationTitle("Haiku")
            .transcriptDebugMenu(
                session,
                isPresented: $showTranscript,
                configuration: .systemModel(Self.model)
            )
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
                    text = "Couldn't generate a haiku: \(error.localizedDescription)"
                }
            }
        }
    }
}

//
//  Created by Artem Novichkov on 17.08.2025.
//

import SwiftUI
import FoundationModels
import TranscriptDebugMenu

struct ContentView: View {
    @State private var text = "Loading..."
    @State private var session = LanguageModelSession(tools: [MoodTool()]) {
        "You're a helpful assistant that generates haikus. Use the `generateMood` tool to get a random mood for the haiku."
    }
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

final class MoodTool: Tool {

    let name = "generateMood"
    let description = "Generates a random mood for haiku"

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> GeneratedContent {
        let moods = ["happy", "sad", "thoughtful", "excited", "calm"]
        return GeneratedContent(properties: ["mood": moods.randomElement()])
    }
}

#Preview {
    ContentView()
}

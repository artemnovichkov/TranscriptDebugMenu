//
//  Created by Artem Novichkov on 17.08.2025.
//

import SwiftUI
import TranscriptDebugMenu
import FoundationModels

struct ContentView: View {
    @State private var session = LanguageModelSession(tools: [MoodTool()]) {
        "You are a haiku generator."
    }
    @State private var showDebugMenu = true
    var body: some View {
        VStack {
            Button("Show Transcript Debug Menu") {
                showDebugMenu.toggle()
            }
        }
        .padding()
        .task {
            do {
                let stream = session.streamResponse(to: "Generate a haiku about Swift")
                for try await _ in stream {
                }
            } catch {
                print("Error: \(error)")
            }
        }
        .transcriptDebugMenu(session, isPresented: $showDebugMenu)
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

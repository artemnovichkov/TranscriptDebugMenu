//
//  Created by Artem Novichkov on 17.08.2025.
//

import SwiftUI
import FoundationModels
import TranscriptDebugMenu

struct ContentView: View {
    @State private var isLoading = false
    @State private var text = ""
    @State private var session = LanguageModelSession(tools: [MoodTool()]) {
        "You're a helpful assistant that generates haiku."
    }
    @State private var showTranscript = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
            } else {
                Text(text)
            }
        }
        .navigationTitle("Haiku")
        .toolbar {
            ToolbarItem {
                Button {
                    showTranscript.toggle()
                } label: {
                    Label("Transcript", systemImage: "gear")
                }
            }
        }
        .transcriptDebugMenu(session, isPresented: $showTranscript)
        .onAppear {
            Task {
                do {
                    isLoading = true
                    let response = try await session.respond(to: "Generate a haiku about Swift")
                    text = response.content
                    isLoading = false
                } catch {
                    isLoading = false
                    print("Error: \(error)")
                }
            }
        }
    }
}

@Generable
enum Mood: String, CaseIterable {
    case happy, sad, thoughtful, excited, calm
}

final class MoodTool: Tool {
    let name = "generateMood"
    let description = "Generates a mood for haiku"

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> GeneratedContent {
        GeneratedContent(properties: ["mood": Mood.allCases.randomElement()])
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}

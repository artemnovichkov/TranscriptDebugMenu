import SwiftUI
import FoundationModels

struct ContentView: View {
    @State private var text = "Loading..."
    @State private var session = LanguageModelSession()

    var body: some View {
        NavigationStack {
            VStack {
                Text(text)
            }
            .padding(.horizontal)
            .navigationTitle("Haiku")
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

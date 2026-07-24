//
//  Created by Artem Novichkov on 17.08.2025.
//

import FoundationModels

@Generable
enum Mood: String, CaseIterable {
    case happy, sad, thoughtful, excited, calm
}

final class MoodTool: Tool {
    let name = "generateMood"
    let description = "Generates a random mood for haiku"

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> Mood? {
        .allCases.randomElement()
    }
}

@Generable
enum PoemStyle: String, CaseIterable {
    case haiku, tanka, freeVerse
}

final class PoemStyleTool: Tool {
    let name = "pickPoemStyle"
    let description = "Picks a poem style to write in"

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> PoemStyle? {
        .allCases.randomElement()
    }
}

@Generable
struct Topics {
    @Guide(description: "Key topics found in the text")
    let topics: [String]
}

@Generable
struct Haiku {
    let text: String
}

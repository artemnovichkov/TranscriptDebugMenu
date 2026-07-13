//
//  Created by Artem Novichkov on 17.08.2025.
//

enum SearchScope: String, CaseIterable, Identifiable {
    case all
    case instructions
    case prompt
    case response
    case toolCalls
    case toolOutput
    case reasoning

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .instructions: "📝"
        case .prompt: "🧍"
        case .response: "🤖"
        case .toolCalls: "📥"
        case .toolOutput: "📤"
        case .reasoning: "🧠"
        }
    }
}

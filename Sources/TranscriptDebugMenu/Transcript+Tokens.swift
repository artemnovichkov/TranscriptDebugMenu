//
//  Created by Artem Novichkov on 27.08.2025.
//

import FoundationModels

extension Transcript {
    var tokensCount: Int {
        reduce(0) { $0 + $1.tokensCount }
    }
}

extension Transcript.Entry {
    var tokensCount: Int {
        let count = switch self {
        case .instructions(let instructions):
            instructions.segments.charactersCount +
            instructions.toolDefinitions.charactersCount
        case .prompt(let prompt):
            prompt.segments.charactersCount +
            (prompt.responseFormat?.description.count ?? 0)
        case .toolCalls(let toolCalls):
            toolCalls.charactersCount
        case .toolOutput(let toolOutput):
            toolOutput.segments.charactersCount
        case .response(let response):
            response.segments.charactersCount
        @unknown default:
            0
        }
        return count / 4
    }
}

private extension Array where Element == Transcript.Segment {
    var charactersCount: Int { reduce(0) { $0 + $1.charactersCount } }
}

private extension Array where Element == Transcript.ToolDefinition {
    var charactersCount: Int { reduce(0) { $0 + $1.charactersCount } }
}

private extension Transcript.ToolCalls {
    var charactersCount: Int { reduce(0) { $0 + $1.arguments.jsonString.count } }
}

private extension Transcript.Segment {
    var charactersCount: Int {
        switch self {
        case .text(let textSegment):
            textSegment.content.count
        case .structure(let structuredSegment):
            structuredSegment.content.jsonString.count
        @unknown default:
            0
        }
    }
}

private extension Transcript.ToolDefinition {
    var charactersCount: Int { name.count + description.count }
}

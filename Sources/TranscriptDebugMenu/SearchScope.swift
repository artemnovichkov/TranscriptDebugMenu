//
//  Created by Artem Novichkov on 17.08.2025.
//

import FoundationModels

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

enum TranscriptFilter {
    static func filter(
        _ transcript: Transcript,
        searchText: String,
        scope: SearchScope
    ) -> Transcript {
        guard !searchText.isEmpty else { return transcript }
        let entries = transcript.filter { entry in
            scope.includes(entry) && entry.searchableText.localizedCaseInsensitiveContains(searchText)
        }
        return Transcript(entries: entries)
    }
}

private extension SearchScope {
    func includes(_ entry: Transcript.Entry) -> Bool {
        switch self {
        case .all:
            true
        case .instructions:
            if case .instructions = entry { true } else { false }
        case .prompt:
            if case .prompt = entry { true } else { false }
        case .response:
            if case .response = entry { true } else { false }
        case .toolCalls:
            if case .toolCalls = entry { true } else { false }
        case .toolOutput:
            if case .toolOutput = entry { true } else { false }
        case .reasoning:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .reasoning = entry {
                true
            } else {
                false
            }
        }
    }
}

extension Transcript.Entry {
    var searchableText: String {
        var values = [id, description]
        switch self {
        case .instructions(let instructions):
            values.append(contentsOf: Self.searchableValues(for: instructions.segments))
            for tool in instructions.toolDefinitions {
                values.append(contentsOf: [tool.name, tool.description])
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                    values.append(DebugJSON.prettyPrinted(tool.parameters))
                }
            }
        case .prompt(let prompt):
            values.append(contentsOf: Self.searchableValues(for: prompt.segments))
            values.append(String(describing: prompt.options))
            if let format = prompt.responseFormat {
                values.append(contentsOf: [format.name, format.description])
            }
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                values.append(contentsOf: prompt.metadata.map { "\($0.key) \($0.value.jsonString)" })
                values.append(String(describing: prompt.contextOptions))
            }
        case .toolCalls(let calls):
            for call in calls {
                values.append(contentsOf: [call.id, call.toolName, call.arguments.jsonString])
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                    values.append(contentsOf: call.metadata.map { "\($0.key) \($0.value.jsonString)" })
                }
            }
        case .toolOutput(let output):
            values.append(output.toolName)
            values.append(contentsOf: Self.searchableValues(for: output.segments))
        case .response(let response):
            values.append(contentsOf: response.assetIDs)
            values.append(contentsOf: response.metadata.map { "\($0.key) \($0.value.jsonString)" })
            values.append(contentsOf: Self.searchableValues(for: response.segments))
        default:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .reasoning(let reasoning) = self {
                values.append(contentsOf: reasoning.metadata.map { "\($0.key) \($0.value.jsonString)" })
                values.append(contentsOf: Self.searchableValues(for: reasoning.segments))
            }
        }
        return values.joined(separator: "\n")
    }

    private static func searchableValues(for segments: [Transcript.Segment]) -> [String] {
        segments.flatMap { segment -> [String] in
            switch segment {
            case .text(let value):
                return [value.id, value.content]
            case .structure(let value):
                return [value.id, value.schemaName, value.content.jsonString]
            default:
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .attachment(let value) = segment {
                    var result = [value.id, value.label ?? "", String(describing: value.content)]
                    if case .image(let image) = value.content, let url = image.url {
                        result.append(url.absoluteString)
                    }
                    return result
                }
                return [segment.description]
            }
        }
    }
}

//
//  Created by Artem Novichkov on 04.08.2025.
//

import FoundationModels

extension Transcript {
    static let mock: Transcript = .init(entries: [
        .instructionsMock,
        .promptMock,
        .toolCallsMock,
        .toolOutputMock,
        .responseMock
    ])
}

extension Transcript.Entry {
    static let instructionsMock: Self = .instructions(.init(segments: Mock.segments, toolDefinitions: [.init(tool: MoodTool())]))

    static let promptMock: Self = .prompt(.init(segments: Mock.segments,
                                                options: .init(sampling: .random(probabilityThreshold: 1), temperature: 1, maximumResponseTokens: 30),
                                                responseFormat: .init(type: Mood.self)))

    static let toolCallsMock: Self = {
        let call = Transcript.ToolCall(id: "id", toolName: MoodTool().name, arguments: MoodTool.Arguments().generatedContent)
        return .toolCalls(Transcript.ToolCalls([call]))
    }()

    static let toolOutputMock: Self = .toolOutput(.init(id: "id", toolName: MoodTool().name, segments: Mock.segments))
    
    static let responseMock: Self = .response(.init(assetIDs: ["id"], segments: Mock.segments))
}

enum Mock {
    static let segments: [Transcript.Segment] = [.text(.init(content: "Text segment"))]
}

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
struct Haiku {
    let text: String
}

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
    static let instructionsMock: Self = .instructions(.init(segments: Mock.instructions, toolDefinitions: [.init(tool: MoodTool())]))

    static let promptMock: Self = .prompt(.init(segments: Mock.prompt,
                                                options: .init(sampling: .random(probabilityThreshold: 1), temperature: 1, maximumResponseTokens: 30)))

    static let toolCallsMock: Self = {
        let call = Transcript.ToolCall(id: "id", toolName: MoodTool().name, arguments: MoodTool.Arguments().generatedContent)
        return .toolCalls(Transcript.ToolCalls([call]))
    }()

    static let toolOutputMock: Self = .toolOutput(.init(id: "id", toolName: MoodTool().name, segments: Mock.toolOutput))

    static let responseMock: Self = .response(.init(assetIDs: Mock.assetIDs, segments: Mock.response))
}

enum Mock {
    static let instructions: [Transcript.Segment] = [.text(.init(content: "You're a helpful assistant that generates haiku."))]
    static let prompt: [Transcript.Segment] = [.text(.init(content: "Generate a haiku about Swift"))]
    static let toolOutput: [Transcript.Segment] = [.text(.init(content: #"{"mood": "calm"}"#))]
    static let response: [Transcript.Segment] = [.text(.init(content: "In Swift's calm embrace,\nCode flows like a gentle stream,\nInnovation blooms."))]

    static let assetIDs: [String] = [
        "com.apple.fm.language.instruct_3b.fm_api_generic_12.0.0.13.101732,0",
        "com.apple.fm.language.instruct_3b.tokenizer_12.0.0.13.202232,0",
        "com.apple.fm.language.instruct_3b.fm_api_generic.draft_12.0.81319.13.202252,0"
    ]
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

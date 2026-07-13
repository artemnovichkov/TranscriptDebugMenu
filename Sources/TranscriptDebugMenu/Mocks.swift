//
//  Created by Artem Novichkov on 04.08.2025.
//

import FoundationModels
import Foundation
import CoreGraphics

extension Transcript {
    static let mock: Transcript = .init(entries: [
        .instructionsMock,
        .promptMock,
        .toolCallsMock,
        .toolOutputMock,
        .responseMock
    ])
}

extension GenerationOptions {
    static let mock: Self = .init(samplingMode: .random(probabilityThreshold: 1), temperature: 1, maximumResponseTokens: 30)
}

extension Transcript.Entry {
    static let instructionsMock: Self = .instructions(.init(segments: Mock.instructions, toolDefinitions: [.init(tool: MoodTool())]))

    static let promptMock: Self = .prompt(.init(segments: Mock.prompt,
                                                options: .mock))

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    static let promptMockFull: Self = .prompt(.init(
        metadata: ["session_id": "abc123", "version": "2"],
        segments: Mock.prompt,
        options: .mock,
        contextOptions: .init(includeSchemaInPrompt: true, reasoningLevel: .moderate)
    ))

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    static let promptMockWithAttachment: Self = .prompt(.init(segments: Mock.attachmentSegments))

    static let toolCallsMock: Self = {
        let call = Transcript.ToolCall(id: "id", toolName: MoodTool().name, arguments: MoodTool.Arguments().generatedContent)
        return .toolCalls(Transcript.ToolCalls([call]))
    }()

    static let toolOutputMock: Self = .toolOutput(.init(id: "id", toolName: MoodTool().name, segments: Mock.toolOutput))

    static let responseMock: Self = .response(.init(assetIDs: Mock.assetIDs, segments: Mock.response))

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    static let reasoningMock: Self = .reasoning(.init(metadata: ["thinking_tokens": 512], segments: Mock.reasoning, signature: nil))
}

enum Mock {
    static let instructions: [Transcript.Segment] = [.text(.init(content: "You're a helpful assistant that generates haiku."))]
    static let prompt: [Transcript.Segment] = [.text(.init(content: "Generate a haiku about Swift"))]
    static let toolOutput: [Transcript.Segment] = [.text(.init(content: #"{"mood": "calm"}"#))]
    static let response: [Transcript.Segment] = [.text(.init(content: "In Swift's calm embrace,\nCode flows like a gentle stream,\nInnovation blooms."))]

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    static let reasoning: [Transcript.Segment] = [.text(.init(content: "Let me think about how to write a haiku about Swift. A haiku has three lines: 5-7-5 syllables. Swift's key traits are speed, safety, and expressiveness. I'll craft something poetic around these."))]

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    static let attachmentSegments: [Transcript.Segment] = {
        var pixels = [UInt8](repeating: 128, count: 4)
        let ctx = CGContext(data: &pixels, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let image = Transcript.ImageAttachment(ctx.makeImage()!)
        let attachment = Transcript.AttachmentSegment(id: "att1", content: .image(image), label: "haiku-photo")
        return [
            .text(.init(content: "Here is an image:")),
            .attachment(attachment)
        ]
    }()

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

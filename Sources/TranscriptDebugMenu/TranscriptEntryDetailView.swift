//
//  Created by Artem Novichkov on 24.08.2025.
//

import SwiftUI
import FoundationModels

/// A SwiftUI view for displaying detailed information about a transcript entry.
struct TranscriptEntryDetailView: View {
    let entry: Transcript.Entry
    @State private var subtitle: LocalizedStringKey = ""

    var body: some View {
        content
            .navigationTitle(entry.title)
            #if !os(visionOS)
            .navigationSubtitle(subtitle)
            #endif
            .tint(entry.accentColor)
            .toolbar {
                ToolbarItem {
                    Button("Copy") {
                        copyToClipboard()
                    }
                }
            }
            .task {
                subtitle = await TokenCounter.formattedCount(for: [entry]) ?? ""
            }
    }
    
    // MARK: - Private

    @ContentBuilder
    private var content: some View {
        Form {
            Section {
                LabeledContent("ID", value: entryID)
            }
            switch entry {
            case .instructions(let instructions):
                instructionsSections(instructions: instructions)
            case .prompt(let prompt):
                promptSections(prompt: prompt)
            case .toolCalls(let toolCalls):
                toolCallsSections(toolCalls: toolCalls)
            case .toolOutput(let toolOutput):
                toolOutputSections(toolOutput: toolOutput)
            case .response(let response):
                responseSections(response: response)
            default:
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                    if case .reasoning(let reasoning) = entry {
                        reasoningSections(reasoning: reasoning)
                    }
                }
            }
        }
    }

    private var entryID: String {
        switch entry {
        case .instructions(let instructions):
            return instructions.id
        case .prompt(let prompt):
            return prompt.id
        case .toolCalls(let toolCalls):
            return toolCalls.id
        case .toolOutput(let toolOutput):
            return toolOutput.id
        case .response(let response):
            return response.id
        default:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .reasoning(let reasoning) = entry {
                return reasoning.id
            }
            return "Unknown"
        }
    }

    // MARK: - Sections

    @ContentBuilder
    private func instructionsSections(instructions: Transcript.Instructions) -> some View {
        segmentsSection(segments: instructions.segments)
        if instructions.toolDefinitions.isEmpty == false {
            Section("Tool definitions") {
                VStack(alignment: .leading) {
                    ForEach(instructions.toolDefinitions, id: \.name) { toolDefinition in
                        LabeledContent(toolDefinition.name, value: toolDefinition.description)
                        if toolDefinition != instructions.toolDefinitions.last {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    @ContentBuilder
    private func promptSections(prompt: Transcript.Prompt) -> some View {
        segmentsSection(segments: prompt.segments)
        if prompt.options.isEmpty == false {
            Section("Options") {
                if let maximumResponseTokens = prompt.options.maximumResponseTokens {
                    LabeledContent("Maximum Response Tokens", value: "\(maximumResponseTokens)")
                }
                if let samplingMode = prompt.options.samplingMode {
                    LabeledContent("Sampling mode", value: "\(samplingMode)")
                }
                if let temperature = prompt.options.temperature {
                    LabeledContent("Temperature", value: "\(temperature)")
                }
            }
        }
        if let responseFormat = prompt.responseFormat {
            Section("Response Format") {
                LabeledContent("Name", value: responseFormat.name)
                LabeledContent("Description", value: responseFormat.description)
            }
        }
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            let ctx = prompt.contextOptions
            if ctx.includeSchemaInPrompt != nil || ctx.reasoningLevel != nil {
                Section("Context Options") {
                    if let includeSchemaInPrompt = ctx.includeSchemaInPrompt {
                        LabeledContent("Include Schema In Prompt", value: includeSchemaInPrompt ? "Yes" : "No")
                    }
                    if let reasoningLevel = ctx.reasoningLevel {
                        LabeledContent("Reasoning Level", value: "\(reasoningLevel)")
                    }
                }
            }
            metadataSection(prompt.metadata)
        }
    }

    private func toolCallsSections(toolCalls: Transcript.ToolCalls) -> some View {
        Section("Tool Calls") {
            ForEach(toolCalls) { call in
                LabeledContent("Tool name", value: call.toolName)
                LabeledContent("Arguments", value: call.arguments.jsonString)
            }
        }
    }

    @ContentBuilder
    private func toolOutputSections(toolOutput: Transcript.ToolOutput) -> some View {
        Section("Tool Output") {
            LabeledContent("Tool name", value: toolOutput.toolName)
        }
        segmentsSection(segments: toolOutput.segments)
    }

    @ContentBuilder
    private func responseSections(response: Transcript.Response) -> some View {
        Section("Asset IDs") {
            LabeledContent("IDs", value: response.assetIDs.description)
        }
        metadataSection(response.metadata)
        segmentsSection(segments: response.segments)
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    @ContentBuilder
    private func reasoningSections(reasoning: Transcript.Reasoning) -> some View {
        segmentsSection(segments: reasoning.segments)
        metadataSection(reasoning.metadata)
        if reasoning.signature != nil {
            Section("Signature") {
                Text("Present")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helper Views

    @ContentBuilder
    private func metadataSection(_ metadata: [String: any Codable & Sendable & Equatable]) -> some View {
        if metadata.isEmpty == false {
            Section("Metadata") {
                ForEach(Array(metadata.keys), id: \.self) { key in
                    LabeledContent(key, value: "\(metadata[key]!)")
                }
            }
        }
    }

    @ContentBuilder
    private func segmentsSection(segments: [Transcript.Segment]) -> some View {
        Section("Segments") {
            VStack(alignment: .leading) {
                ForEach(segments) { segment in
                    switch segment {
                    case .text(let textSegment):
                        LabeledContent("ID", value: textSegment.id)
                        LabeledContent("Content", value: textSegment.content)
                    case .structure(let structuredSegment):
                        LabeledContent("Source", value: structuredSegment.source)
                        LabeledContent("Content", value: structuredSegment.content.jsonString)
                    default:
                        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .attachment(let attachment) = segment {
                            LabeledContent("ID", value: attachment.id)
                            switch attachment.content {
                            case .image:
                                LabeledContent {
                                    Image(systemName: "photo")
                                } label: {
                                    Text("Image")
                                }
                            @unknown default:
                                EmptyView()
                            }
                            if let label = attachment.label {
                                LabeledContent("Content", value: label)
                            }
                        }
                        EmptyView()
                    }
                    if segment != segments.last {
                        Divider()
                    }
                }
            }
        }
    }

    private func copyToClipboard() {
        #if canImport(UIKit)
        UIPasteboard.general.string = entry.description
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(entry.description, forType: .string)
        #endif
    }
}

private extension GenerationOptions {
    var isEmpty: Bool {
        maximumResponseTokens == nil && temperature == nil && samplingMode == nil
    }
}

#Preview("Instructions") {
    NavigationStack {
        TranscriptEntryDetailView(entry: .instructionsMock)
    }
}

#Preview("Prompt") {
    NavigationStack {
        TranscriptEntryDetailView(entry: .promptMock)
    }
}

#Preview("Prompt (Full)") {
    if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
        NavigationStack {
            TranscriptEntryDetailView(entry: .promptMockFull)
        }
    }
}

#Preview("Prompt (With Attachment)") {
    if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
        NavigationStack {
            TranscriptEntryDetailView(entry: .promptMockWithAttachment)
        }
    }
}

#Preview("Tool Calls") {
    NavigationStack {
        TranscriptEntryDetailView(entry: .toolCallsMock)
    }
}

#Preview("Tool Output") {
    NavigationStack {
        TranscriptEntryDetailView(entry: .toolOutputMock)
    }
}

#Preview("Response") {
    NavigationStack {
        TranscriptEntryDetailView(entry: .responseMock)
    }
}

#Preview("Reasoning") {
    if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
        NavigationStack {
            TranscriptEntryDetailView(entry: .reasoningMock)
        }
    }
}

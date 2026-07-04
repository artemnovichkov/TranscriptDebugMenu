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
        Form {
            content
        }
        .navigationTitle(title)
        #if !os(visionOS)
        .navigationSubtitle(subtitle)
        #endif
        .toolbar {
            ToolbarItem {
                Button("Copy") {
                    copyToClipboard()
                }
            }
        }
        .task {
            if let formatted = await TokenCounter.formattedCount(for: [entry]) {
                subtitle = formatted
            }
        }
    }
    
    // MARK: - Private

    @ContentBuilder
    private var content: some View {
        Section("ID") {
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
        @unknown default:
            reasoningView
        }
    }

    private var entryID: String {
        switch entry {
        case .instructions(let instructions):
            instructions.id
        case .prompt(let prompt):
            prompt.id
        case .toolCalls(let toolCalls):
            toolCalls.id
        case .toolOutput(let toolOutput):
            toolOutput.id
        case .response(let response):
            response.id
        @unknown default:
            unknownEntryID
        }
    }

    private var unknownEntryID: String {
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .reasoning(let reasoning) = entry {
            return reasoning.id
        }
        return "Unknown"
    }

    @ContentBuilder
    private var reasoningView: some View {
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            if case .reasoning(let reasoning) = entry {
                reasoningSections(reasoning: reasoning)
            }
        }
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    @ContentBuilder
    private func reasoningSections(reasoning: Transcript.Reasoning) -> some View {
        segmentsSection(segments: reasoning.segments)
        if reasoning.signature != nil {
            Section("Signature") {
                Text("Present")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ContentBuilder
    private func instructionsSections(instructions: Transcript.Instructions) -> some View {
        segmentsSection(segments: instructions.segments)
        if instructions.toolDefinitions.isEmpty == false {
            Section("Tool definitions") {
                VStack(alignment: .leading) {
                    ForEach(instructions.toolDefinitions, id: \.name) { toolDefinition in
                        Text("Name")
                        Text(toolDefinition.name)
                            .foregroundStyle(.secondary)
                            .padding(.bottom)
                        Text("Description")
                        Text(toolDefinition.description)
                            .foregroundStyle(.secondary)
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
        segmentsSection(segments: response.segments)
    }

    @ContentBuilder
    private func segmentsSection(segments: [Transcript.Segment]) -> some View {
        if segments.isEmpty == false {
            Section("Segments") {
                ForEach(segments) { segment in
                    switch segment {
                    case .text(let textSegment):
                        LabeledContent("Text", value: textSegment.content)
                    case .structure(let structuredSegment):
                        LabeledContent("Source", value: structuredSegment.source)
                        LabeledContent("Content", value: structuredSegment.content.jsonString)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }

    private var title: String {
        switch entry {
        case .instructions:
            "Instructions"
        case .prompt:
            "Prompt"
        case .response:
            "Response"
        case .toolCalls:
            "Tool Calls"
        case .toolOutput:
            "Tool Output"
        @unknown default:
            unknownTitle
        }
    }

    private var unknownTitle: String {
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *), case .reasoning = entry {
            return "Reasoning"
        }
        return "Unknown"
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

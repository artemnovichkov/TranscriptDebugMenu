//
//  Created by Artem Novichkov on 24.08.2025.
//

import CoreGraphics
import SwiftUI
import FoundationModels
import OSLog

/// A SwiftUI view for displaying detailed information about a transcript entry.
struct TranscriptEntryDetailView: View {
    let entry: Transcript.Entry
    let contextMetricsProvider: TranscriptDebugMenu.ContextMetricsProvider?
    @State private var subtitle: LocalizedStringKey = ""
    @State private var selectedImage: ImagePreviewItem?

    private let logger = Logger(
        subsystem: "com.artemnovichkov.TranscriptDebugMenu",
        category: "TranscriptEntryDetailView"
    )

    init(
        entry: Transcript.Entry,
        contextMetricsProvider: TranscriptDebugMenu.ContextMetricsProvider? = nil
    ) {
        self.entry = entry
        self.contextMetricsProvider = contextMetricsProvider
    }

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
            .task(id: ContextMetricsRequest(
                transcript: Transcript(entries: [entry]),
                providerID: contextMetricsProvider?.id
            )) {
                await refreshSubtitle()
            }
            .sheet(item: $selectedImage) { item in
                AttachmentImagePreview(item: item)
            }
    }
    
    // MARK: - Private

    @ContentBuilder
    private var content: some View {
        Form {
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
            technicalDetailsSection
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
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(instructions.toolDefinitions.enumerated()), id: \.offset) { index, toolDefinition in
                        DebugValueRow("Name", value: toolDefinition.name)
                        DebugValueRow("Description", value: toolDefinition.description)
                        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                            DebugValueRow("Parameters", value: DebugJSON.prettyPrinted(toolDefinition.parameters))
                        }
                        if index < instructions.toolDefinitions.count - 1 {
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
        if prompt.options.hasInspectableValues {
            Section("Generation Options") {
                if let maximumResponseTokens = prompt.options.maximumResponseTokens {
                    DebugValueRow("Maximum Response Tokens", value: "\(maximumResponseTokens)")
                }
                if let samplingMode = prompt.options.samplingMode {
                    DebugValueRow("Sampling Mode", value: samplingMode.debugDescription)
                }
                if let temperature = prompt.options.temperature {
                    DebugValueRow("Temperature", value: "\(temperature)")
                }
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *),
                   let toolCallingMode = prompt.options.toolCallingMode {
                    DebugValueRow("Tool Calling Mode", value: String(describing: toolCallingMode.kind))
                }
            }
        }
        if let responseFormat = prompt.responseFormat {
            Section("Response Format") {
                DebugValueRow("Name", value: responseFormat.name)
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                    switch responseFormat.kind {
                    case .schema(let schema):
                        DisclosureGroup("Schema") {
                            contentText(DebugJSON.prettyPrinted(schema), monospaced: true)
                        }
                    @unknown default:
                        DisclosureGroup("Format") {
                            contentText(responseFormat.description, monospaced: true)
                        }
                    }
                } else {
                    DisclosureGroup("Format") {
                        contentText(responseFormat.description, monospaced: true)
                    }
                }
            }
        }
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            let ctx = prompt.contextOptions
            if ctx.includeSchemaInPrompt != nil || ctx.reasoningLevel != nil {
                Section("Context Options") {
                    if let includeSchemaInPrompt = ctx.includeSchemaInPrompt {
                        DebugValueRow("Include Schema In Prompt", value: includeSchemaInPrompt ? "Yes" : "No")
                    }
                    if let reasoningLevel = ctx.reasoningLevel {
                        DebugValueRow("Reasoning Level", value: "\(reasoningLevel)")
                    }
                }
            }
            metadataSection(prompt.metadata)
        }
    }

    private func toolCallsSections(toolCalls: Transcript.ToolCalls) -> some View {
        Section("Tool Calls") {
            ForEach(Array(toolCalls.enumerated()), id: \.element.id) { index, call in
                VStack(alignment: .leading, spacing: 8) {
                    DebugValueRow("Tool Name", value: call.toolName)
                    contentText(DebugJSON.prettyPrinted(call.arguments), monospaced: true)
                    if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                        metadataRows(call.metadata)
                    }
                }
                if index < toolCalls.count - 1 {
                    Divider()
                }
            }
        }
    }

    @ContentBuilder
    private func toolOutputSections(toolOutput: Transcript.ToolOutput) -> some View {
        segmentsSection(segments: toolOutput.segments)
        Section("Tool Output") {
            DebugValueRow("Tool Name", value: toolOutput.toolName)
        }
    }

    @ContentBuilder
    private func responseSections(response: Transcript.Response) -> some View {
        segmentsSection(segments: response.segments)
        metadataSection(response.metadata)
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    @ContentBuilder
    private func reasoningSections(reasoning: Transcript.Reasoning) -> some View {
        segmentsSection(segments: reasoning.segments)
        metadataSection(reasoning.metadata)
    }

    // MARK: - Helper Views

    @ContentBuilder
    private func metadataSection(_ metadata: [String: GeneratedContent]) -> some View {
        if metadata.isEmpty == false {
            Section("Metadata") {
                metadataRows(metadata)
            }
        }
    }

    @ViewBuilder
    private func metadataRows(_ metadata: [String: GeneratedContent]) -> some View {
        ForEach(metadata.keys.sorted(), id: \.self) { key in
            if let value = metadata[key] {
                DebugValueRow(LocalizedStringKey(key), value: DebugJSON.prettyPrinted(value))
            }
        }
    }

    @ContentBuilder
    private func segmentsSection(segments: [Transcript.Segment]) -> some View {
        ForEach(segments) { segment in
            Section {
                segmentContent(segment)
            } header: {
                if segments.count > 1 {
                    Text(segmentTitle(segment))
                }
            }
        }
    }

    private func segmentTitle(_ segment: Transcript.Segment) -> LocalizedStringKey {
        switch segment {
        case .text: "Text"
        case .structure: "Structured Content"
        default: "Attachment"
        }
    }

    @ViewBuilder
    private func segmentContent(_ segment: Transcript.Segment) -> some View {
        switch segment {
        case .text(let text):
            contentText(text.content)
        case .structure(let structure):
            DebugValueRow("Schema", value: structure.schemaName)
            contentText(DebugJSON.prettyPrinted(structure.content), monospaced: true)
        default:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *),
               case .attachment(let attachment) = segment {
                switch attachment.content {
                case .image(let image):
                    Button {
                        selectedImage = ImagePreviewItem(id: attachment.id, image: image.cgImage)
                    } label: {
                        Image(decorative: image.cgImage, scale: 1)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(attachment.label ?? "Preview image attachment")
                    DebugValueRow("Size", value: "\(image.cgImage.width) × \(image.cgImage.height)")
                    DebugValueRow("Orientation", value: "\(image.orientation.rawValue)")
                    if let url = image.url {
                        DebugValueRow("URL", value: url.absoluteString)
                    }
                @unknown default:
                    contentText(String(describing: attachment.content))
                }
                if let label = attachment.label {
                    DebugValueRow("Label", value: label)
                }
            } else {
                contentText(segment.description)
            }
        }
    }

    private func contentText(_ value: String, monospaced: Bool = false) -> some View {
        Text(value)
            .font(monospaced ? .system(.body, design: .monospaced) : .body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .contextMenu {
                Button("Copy", systemImage: "document.on.document") {
                    DebugClipboard.copy(value)
                }
            }
    }

    private var entrySegments: [Transcript.Segment] {
        switch entry {
        case .instructions(let value): return value.segments
        case .prompt(let value): return value.segments
        case .response(let value): return value.segments
        case .toolOutput(let value): return value.segments
        default:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *),
               case .reasoning(let value) = entry {
                return value.segments
            }
            return []
        }
    }

    private var technicalDetailsSection: some View {
        Section {
            DisclosureGroup("Technical Details") {
                DebugValueRow("Entry ID", value: entryID)
                ForEach(Array(entrySegments.enumerated()), id: \.element.id) { index, segment in
                    DebugValueRow("Segment \(index + 1) ID", value: segment.id)
                }
                if case .toolCalls(let calls) = entry {
                    ForEach(Array(calls.enumerated()), id: \.element.id) { index, call in
                        DebugValueRow("Tool Call \(index + 1) ID", value: call.id)
                    }
                }
                if case .response(let response) = entry, !response.assetIDs.isEmpty {
                    DebugValueRow("Asset IDs", value: response.assetIDs.joined(separator: "\n"))
                }
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *),
                   case .reasoning(let reasoning) = entry,
                   let signature = reasoning.signature {
                    DebugValueRow("Signature Size", value: "\(signature.count) bytes")
                    DebugValueRow("Signature Base64", value: signature.base64EncodedString())
                }
            }
        }
    }

    private func copyToClipboard() {
        DebugClipboard.copy(entry.description)
    }

    @MainActor
    private func refreshSubtitle() async {
        subtitle = ""
        guard let contextMetricsProvider else {
            subtitle = ""
            return
        }
        do {
            let metrics = try await contextMetricsProvider.metrics(for: Transcript(entries: [entry]))
            try Task.checkCancellation()
            guard metrics.isValid else {
                subtitle = ""
                logger.error("Entry context metrics must use a nonnegative token count and a positive context size.")
                return
            }
            subtitle = TokenCounter.formattedCount(
                for: (metrics.tokenCount, metrics.contextSize)
            )
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            subtitle = ""
            logger.error("Failed to get entry context metrics: \(error.localizedDescription)")
        }
    }
}

private struct ImagePreviewItem: Identifiable {
    let id: String
    let image: CGImage
}

private struct AttachmentImagePreview: View {
    let item: ImagePreviewItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                Image(decorative: item.image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
            .navigationTitle("Attachment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
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

#Preview("Tool Calls (Full)") {
    if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
        NavigationStack {
            TranscriptEntryDetailView(entry: .toolCallsMockFull)
        }
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

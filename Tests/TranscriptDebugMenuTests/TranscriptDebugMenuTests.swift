import Foundation
import FoundationModels
import Testing
@testable import TranscriptDebugMenu

@Suite("TranscriptDebugMenu")
struct TranscriptDebugMenuTests {
    @Test("Transcript JSON is pretty printed and round-trips")
    func transcriptJSONRoundTrip() throws {
        let json = DebugJSON.prettyPrinted(Transcript.mock)
        #expect(json.contains("\n"))

        let decoded = try JSONDecoder().decode(Transcript.self, from: Data(json.utf8))
        #expect(decoded.count == Transcript.mock.count)
        #expect(decoded.map(\.id) == Transcript.mock.map(\.id))
        #expect(decoded.map(\.description) == Transcript.mock.map(\.description))
    }

    @Test("Generated content JSON is sorted and pretty printed")
    func generatedContentJSON() throws {
        let content = try GeneratedContent(json: #"{"z":1,"a":{"value":true}}"#)
        let json = DebugJSON.prettyPrinted(content)
        #expect(json.firstIndex(of: "a")! < json.firstIndex(of: "z")!)
        #expect(json.contains("\n"))
    }

    @Test("Filtering uses entry scope")
    func scopeFiltering() {
        let result = TranscriptFilter.filter(
            Transcript.mock,
            searchText: "generateMood",
            scope: .toolCalls
        )
        #expect(result.count == 1)
        guard case .toolCalls = result.first else {
            Issue.record("Expected a tool calls entry")
            return
        }
    }

    @Test("Search includes IDs and structured values")
    func expandedSearch() {
        let prompt = Transcript.Entry.prompt(
            .init(id: "searchable-prompt-id", segments: [.text(.init(content: "Hello"))])
        )
        let transcript = Transcript(entries: [prompt])

        #expect(TranscriptFilter.filter(transcript, searchText: "searchable-prompt-id", scope: .all).count == 1)
        #expect(TranscriptFilter.filter(transcript, searchText: "missing", scope: .all).isEmpty)
    }

    @Test("Empty search preserves the original transcript")
    func emptySearch() {
        #expect(TranscriptFilter.filter(Transcript.mock, searchText: "", scope: .response) == Transcript.mock)
    }

    @Test("Custom context provider returns model-specific metrics")
    func contextProvider() async throws {
        let provider = TranscriptDebugMenu.ContextMetricsProvider { transcript in
            .init(tokenCount: transcript.count * 10, contextSize: 1_024)
        }
        let metrics = try await provider.metrics(for: Transcript.mock)
        #expect(metrics == .init(tokenCount: Transcript.mock.count * 10, contextSize: 1_024))
    }

    @Test("Context provider propagates failures")
    func contextProviderFailure() async {
        struct TestFailure: Error {}
        let provider = TranscriptDebugMenu.ContextMetricsProvider { _ in
            throw TestFailure()
        }

        do {
            _ = try await provider.metrics(for: .mock)
            Issue.record("Expected the provider to throw")
        } catch {
            #expect(error is TestFailure)
        }
    }

    @Test("System model diagnostics remain stable when configuration is recreated")
    func systemProviderIdentity() {
        let model = SystemLanguageModel(useCase: .contentTagging)
        let first = TranscriptDebugMenu.Configuration.systemModel(model)
        let second = TranscriptDebugMenu.Configuration.systemModel(model)
        let replacement = TranscriptDebugMenu.Configuration.systemModel(SystemLanguageModel())
        #expect(first.contextMetricsProvider?.id == second.contextMetricsProvider?.id)
        #expect(first.contextMetricsProvider?.id != replacement.contextMetricsProvider?.id)
    }

    @Test("Context provider preserves cancellation")
    func contextProviderCancellation() async {
        let provider = TranscriptDebugMenu.ContextMetricsProvider { _ in
            throw CancellationError()
        }

        do {
            _ = try await provider.metrics(for: .mock)
            Issue.record("Expected the provider to cancel")
        } catch {
            #expect(error is CancellationError)
        }
    }

    @Test("Feedback draft maps selected issues and trims desired response")
    func feedbackDraft() {
        var draft = FeedbackDraft()
        draft.sentiment = .negative
        draft.desiredResponseText = "  Expected answer  \n"
        draft.issueDrafts[0].isSelected = true
        draft.issueDrafts[0].explanation = "  Not useful  "

        #expect(draft.sentiment.value == .negative)
        #expect(draft.issues.count == 1)
        #expect(draft.desiredResponse == "Expected answer")
    }

    @Test("Generation options detect visible values")
    func generationOptionsVisibility() {
        #expect(!GenerationOptions().hasInspectableValues)
        #expect(GenerationOptions(temperature: 0.5).hasInspectableValues)

        if #available(iOS 27.0, macOS 27.0, macCatalyst 27.0, visionOS 27.0, *) {
            let toolOnly = GenerationOptions(toolCallingMode: .required)
            #expect(toolOnly.hasInspectableValues)
        }
    }

    @Test("Search includes structured content and response metadata, ignoring case")
    func structuredSearch() throws {
        let content = try GeneratedContent(json: #"{"city":"Almaty"}"#)
        let segment: Transcript.StructuredSegment
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            segment = .init(schemaName: "Location", content: content)
        } else {
            segment = .init(source: "Location", content: content)
        }
        let response = Transcript.Entry.response(.init(assetIDs: ["request-42"], segments: [.structure(segment)]))
        let transcript = Transcript(entries: [response])
        for query in ["ALMATY", "Location", "request-42"] {
            #expect(TranscriptFilter.filter(transcript, searchText: query, scope: .response).count == 1)
            #expect(TranscriptFilter.filter(transcript, searchText: query, scope: .prompt).isEmpty)
        }
    }

    @Test("OS 27 search includes attachments, reasoning, and tool metadata")
    @available(iOS 27.0, macOS 27.0, macCatalyst 27.0, visionOS 27.0, *)
    func modernSearch() {
        let transcript = Transcript(entries: [.promptMockWithAttachment, .reasoningMock, .toolCallsMockFull])
        #expect(TranscriptFilter.filter(transcript, searchText: "haiku-photo", scope: .prompt).count == 1)
        #expect(TranscriptFilter.filter(transcript, searchText: "thinking_tokens", scope: .reasoning).count == 1)
        #expect(TranscriptFilter.filter(transcript, searchText: "req-42", scope: .toolCalls).count == 1)
    }

    @Test("Context metrics reject invalid counts but preserve over-limit consumption")
    func metricsValidation() {
        #expect(!TranscriptDebugMenu.ContextMetrics(tokenCount: -1, contextSize: 100).isValid)
        #expect(!TranscriptDebugMenu.ContextMetrics(tokenCount: 0, contextSize: 0).isValid)
        #expect(!TranscriptDebugMenu.ContextMetrics(tokenCount: 1, contextSize: -1).isValid)
        #expect(TranscriptDebugMenu.ContextMetrics(tokenCount: 0, contextSize: 100).isValid)
        #expect(TranscriptDebugMenu.ContextMetrics(tokenCount: 101, contextSize: 100).isValid)
        #expect(TranscriptDebugMenu.Configuration().contextMetricsProvider == nil)
    }

    @Test("Diagnostics refresh for changed content with the same entry ID or a new provider")
    func changedMetricsRequest() {
        let first = Transcript(entries: [.prompt(.init(id: "prompt", segments: [.text(.init(content: "First"))]))])
        let second = Transcript(entries: [.prompt(.init(id: "prompt", segments: [.text(.init(content: "Updated"))]))])
        let provider = TranscriptDebugMenu.ContextMetricsProvider { _ in .init(tokenCount: 1, contextSize: 100) }
        let replacement = TranscriptDebugMenu.ContextMetricsProvider { _ in .init(tokenCount: 2, contextSize: 200) }
        let original = ContextMetricsRequest(transcript: first, providerID: provider.id)
        #expect(original == ContextMetricsRequest(transcript: first, providerID: provider.id))
        #expect(original != ContextMetricsRequest(transcript: second, providerID: provider.id))
        #expect(original != ContextMetricsRequest(transcript: first, providerID: replacement.id))
        #expect(original != ContextMetricsRequest(transcript: first, providerID: nil))
    }

    @Test("Export contains the current complete transcript after filtering and appending")
    func updatedExport() throws {
        let original = Transcript.mock
        let filtered = TranscriptFilter.filter(original, searchText: "generateMood", scope: .toolCalls)
        #expect(filtered.count < original.count)
        let updated = Transcript(entries: Array(original) + [.prompt(.init(segments: [.text(.init(content: "Follow-up"))]))])
        let decoded = try JSONDecoder().decode(Transcript.self, from: Data(DebugJSON.prettyPrinted(updated).utf8))
        #expect(decoded.count == original.count + 1)
        #expect(decoded.last?.description.contains("Follow-up") == true)
    }

    @Test("Feedback omits blank values and unselected issues")
    func emptyFeedbackValues() {
        var draft = FeedbackDraft()
        draft.desiredResponseText = " \n "
        draft.issueDrafts[0].explanation = "Unselected explanation"
        #expect(draft.sentiment.value == nil)
        #expect(draft.desiredResponse == nil)
        #expect(draft.issues.isEmpty)
        draft.issueDrafts[0].isSelected = true
        draft.issueDrafts[0].explanation = " \n "
        #expect(draft.issues.count == 1)
    }
}

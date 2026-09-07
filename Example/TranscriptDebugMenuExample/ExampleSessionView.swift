//
//  Created by Artem Novichkov on 24.07.2026.
//

import FoundationModels
import SwiftUI
import TranscriptDebugMenu

struct ExampleSessionView: View {
    let scenario: ExampleScenario

    var body: some View {
        switch scenario {
        case .dynamicProfile:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                DynamicProfileSessionView()
            } else {
                unavailable
            }
        case .profileWithModelSwitch:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                ProfileModelSessionView()
            } else {
                unavailable
            }
        case .imageAttachment:
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
                ImageAttachmentSessionView(scenario: scenario)
            } else {
                unavailable
            }
        default:
            ClassicSessionView(scenario: scenario)
        }
    }

    private var unavailable: some View {
        ContentUnavailableView(
            "Requires iOS 27",
            systemImage: "gear.badge.questionmark",
            description: Text("Dynamic profiles need a newer OS.")
        )
        .navigationTitle(scenario.title)
    }
}

// MARK: - Classic sessions (iOS 26+)

private struct ClassicSessionView: View {
    let scenario: ExampleScenario
    @State private var model: SystemLanguageModel

    @State private var session: LanguageModelSession
    @State private var text = ""
    @State private var errorText: String?
    @State private var isLoading = false
    @State private var showTranscript = false

    init(scenario: ExampleScenario) {
        self.scenario = scenario
        let model = Self.makeModel(for: scenario)
        _model = State(initialValue: model)
        _session = State(initialValue: Self.makeSession(for: scenario, model: model))
    }

    var body: some View {
        SessionResultView(
            title: scenario.title,
            subtitle: scenario.subtitle,
            text: text,
            errorText: errorText,
            isLoading: isLoading,
            showTranscript: $showTranscript,
            onRun: { await run() },
            onReset: {
                text = ""
                errorText = nil
                session = Self.makeSession(for: scenario, model: model)
            }
        )
        .transcriptDebugMenu(
            session,
            isPresented: $showTranscript,
            configuration: .systemModel(model)
        )
    }

    private static func makeModel(for scenario: ExampleScenario) -> SystemLanguageModel {
        switch scenario {
        case .contentTagging:
            SystemLanguageModel(useCase: .contentTagging)
        case .permissiveGuardrails:
            SystemLanguageModel(guardrails: .permissiveContentTransformations)
        default:
            .default
        }
    }

    private static func makeSession(
        for scenario: ExampleScenario,
        model: SystemLanguageModel
    ) -> LanguageModelSession {
        switch scenario {
        case .noTools:
            LanguageModelSession(model: model) {
                "You're a helpful assistant that writes short poems."
            }
        case .withTools:
            LanguageModelSession(model: model, tools: [MoodTool()]) {
                """
                You're a helpful assistant that generates haiku.
                Always call generateMood first, then write a haiku in that mood.
                """
            }
        case .multiTools:
            LanguageModelSession(model: model, tools: [MoodTool(), PoemStyleTool()]) {
                """
                You're a poetry assistant.
                Call pickPoemStyle and generateMood before writing.
                """
            }
        case .structured:
            LanguageModelSession(model: model) {
                "You're a helpful assistant that generates haiku."
            }
        case .contentTagging:
            LanguageModelSession(model: model) {
                "Extract the main topics from the text."
            }
        case .permissiveGuardrails:
            LanguageModelSession(model: model) {
                "You rewrite text clearly and concisely."
            }
        case .dynamicProfile, .profileWithModelSwitch, .imageAttachment:
            LanguageModelSession()
        }
    }

    @MainActor
    private func run() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            switch scenario {
            case .structured:
                let response = try await session.respond(
                    to: scenario.prompt,
                    generating: Haiku.self
                )
                text = response.content.text
            case .contentTagging:
                let response = try await session.respond(
                    to: scenario.prompt,
                    generating: Topics.self
                )
                text = response.content.topics.map { "• \($0)" }.joined(separator: "\n")
            default:
                let response = try await session.respond(to: scenario.prompt)
                text = response.content
            }
        } catch {
            errorText = String(describing: error)
        }
    }
}

// MARK: - Image attachment session (iOS 27+)

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
private struct ImageAttachmentSessionView: View {
    let scenario: ExampleScenario

    @State private var session = LanguageModelSession()
    @State private var text = ""
    @State private var errorText: String?
    @State private var isLoading = false
    @State private var showTranscript = false

    private let sampleImage: CGImage = {
        let size = 200
        let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(CGColor(red: 1, green: 0.3, blue: 0.2, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: size / 2, height: size))
        ctx.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: size / 2, y: 0, width: size / 2, height: size))
        return ctx.makeImage()!
    }()

    var body: some View {
        SessionResultView(
            title: scenario.title,
            subtitle: scenario.subtitle,
            text: text,
            errorText: errorText,
            isLoading: isLoading,
            showTranscript: $showTranscript,
            header: {
                Image(decorative: sampleImage, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            },
            onRun: { await run() },
            onReset: {
                text = ""
                errorText = nil
                session = LanguageModelSession()
            }
        )
        .transcriptDebugMenu(
            session,
            isPresented: $showTranscript,
            configuration: .systemModel(.default)
        )
    }

    @MainActor
    private func run() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let response = try await session.respond {
                scenario.prompt
                Attachment(sampleImage)
            }
            text = response.content
        } catch {
            errorText = String(describing: error)
        }
    }
}

// MARK: - Dynamic profile sessions (iOS 27+)

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
private struct DynamicProfileSessionView: View {
    @State private var state: HaikuProfileState
    @State private var session: LanguageModelSession
    @State private var text = ""
    @State private var errorText: String?
    @State private var isLoading = false
    @State private var showTranscript = false

    init() {
        let state = HaikuProfileState()
        _state = State(initialValue: state)
        _session = State(initialValue: LanguageModelSession(profile: HaikuProfile(state: state)))
    }

    var body: some View {
        SessionResultView(
            title: ExampleScenario.dynamicProfile.title,
            subtitle: ExampleScenario.dynamicProfile.subtitle,
            text: text,
            errorText: errorText,
            isLoading: isLoading,
            showTranscript: $showTranscript,
            header: {
                @Bindable var state = state
                Picker("Mode", selection: $state.mode) {
                    ForEach(HaikuProfileState.Mode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            },
            onRun: { await run() },
            onReset: {
                text = ""
                errorText = nil
                state.mode = .withTools
                session = LanguageModelSession(profile: HaikuProfile(state: state))
            }
        )
        .transcriptDebugMenu(session, isPresented: $showTranscript)
    }

    @MainActor
    private func run() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let response = try await session.respond(to: ExampleScenario.dynamicProfile.prompt)
            text = response.content
        } catch {
            errorText = String(describing: error)
        }
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
private struct ProfileModelSessionView: View {
    @State private var session = LanguageModelSession(profile: ContentTaggingProfile())
    @State private var text = ""
    @State private var errorText: String?
    @State private var isLoading = false
    @State private var showTranscript = false

    var body: some View {
        SessionResultView(
            title: ExampleScenario.profileWithModelSwitch.title,
            subtitle: ExampleScenario.profileWithModelSwitch.subtitle,
            text: text,
            errorText: errorText,
            isLoading: isLoading,
            showTranscript: $showTranscript,
            onRun: { await run() },
            onReset: {
                text = ""
                errorText = nil
                session = LanguageModelSession(profile: ContentTaggingProfile())
            }
        )
        .transcriptDebugMenu(session, isPresented: $showTranscript)
    }

    @MainActor
    private func run() async {
        isLoading = true
        errorText = nil
        defer { isLoading = false }

        do {
            let response = try await session.respond(
                to: ExampleScenario.profileWithModelSwitch.prompt,
                generating: Topics.self
            )
            text = response.content.topics.map { "• \($0)" }.joined(separator: "\n")
        } catch {
            errorText = String(describing: error)
        }
    }
}

// MARK: - Shared UI

private struct SessionResultView<Header: View>: View {
    let title: String
    let subtitle: String
    let text: String
    let errorText: String?
    let isLoading: Bool
    @Binding var showTranscript: Bool
    @ViewBuilder var header: () -> Header
    let onRun: () async -> Void
    let onReset: () -> Void

    init(
        title: String,
        subtitle: String,
        text: String,
        errorText: String?,
        isLoading: Bool,
        showTranscript: Binding<Bool>,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        onRun: @escaping () async -> Void,
        onReset: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.text = text
        self.errorText = errorText
        self.isLoading = isLoading
        self._showTranscript = showTranscript
        self.header = header
        self.onRun = onRun
        self.onReset = onReset
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header()

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Group {
                    if isLoading {
                        ProgressView("Generating…")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let errorText {
                        Text(errorText)
                            .foregroundStyle(.red)
                    } else if text.isEmpty {
                        Text("Tap Run to generate.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(text)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showTranscript = true
                } label: {
                    Label("Transcript", systemImage: "text.alignleft")
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Run") {
                    Task { await onRun() }
                }
                .disabled(isLoading)
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Reset", action: onReset)
                    .disabled(isLoading)
            }
        }
    }
}

# ``TranscriptDebugMenu``

A SwiftUI library for inspecting, searching, exporting, and reporting feedback about `LanguageModelSession` transcripts.

@Metadata {
    @PageImage(
        purpose: icon,
        source: "screenshot1",
        alt: "TranscriptDebugMenu")
    @PageColor(green)
}

@Row {
    @Column {
        ![Screenshot 1](screenshot1)
    }
    @Column {
        ![Screenshot 2](screenshot2)
    }
}

## Description

TranscriptDebugMenu is a lightweight SwiftUI component designed to help developers inspect language model sessions. It displays every transcript entry and its metadata, model-specific context-window metrics, token usage, attachments, generation options, tool calls, reasoning, and structured output.

## Features

- View, search, and filter every transcript entry type;
- Inspect formatted structured content, metadata, tool schemas, attachments, reasoning, and token usage;
- Calculate context-window usage with an explicitly configured model-specific provider;
- Copy individual values or export the complete `Transcript` as formatted JSON;
- Create detailed `LanguageModelFeedback` with sentiment, issue categories, explanations, and a desired response.

## Installation

Version 2.0 is in beta. Select an exact published beta tag from [Releases](https://github.com/artemnovichkov/TranscriptDebugMenu/releases) to try it. The `from: "2.0.0"` example below is for the stable release; use `exact:` with a published beta tag during the beta period.

Add TranscriptDebugMenu to your project using Swift Package Manager:

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/artemnovichkov/TranscriptDebugMenu
   ```
3. Choose the version you want to use
4. Add the package to your target

Alternatively, add it to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/artemnovichkov/TranscriptDebugMenu", from: "2.0.0")
]
```

## Usage

> Check out <doc:/tutorials/TranscriptDebugMenu> tutorial for a step-by-step guide.

Import the library and use the transcript menu modifier on any SwiftUI view:

```swift
import SwiftUI
import FoundationModels
import TranscriptDebugMenu

struct ContentView: View {
    @State private var showTranscript = false
    private static let model = SystemLanguageModel.default
    @State private var session = LanguageModelSession(model: ContentView.model)
    
    var body: some View {
        VStack {
            Button("Show Transcript Menu") {
                showTranscript = true
            }
        }
        .transcriptDebugMenu(
            session,
            isPresented: $showTranscript,
            configuration: .systemModel(Self.model)
        )
    }
}
```

## Requirements

- iOS 26.0+ / macOS 26.0+ / Mac Catalyst 26.0+ / visionOS 26.0+
- Swift 6.4+
- Xcode 27.0+

## Configure context metrics

`LanguageModelSession` doesn't expose its model. Pass the same `SystemLanguageModel` instance used to create the session so the menu uses the correct tokenizer and context size:

```swift
let model = SystemLanguageModel(useCase: .contentTagging)
let session = LanguageModelSession(model: model)
let configuration = TranscriptDebugMenu.Configuration.systemModel(model)
```

For dynamic, cloud, or custom models, pass a custom ``TranscriptDebugMenu/ContextMetricsProvider``. Omit `configuration` when a reliable token counter isn't available; no model is assumed; the menu will hide context progress while continuing to display the session's reported usage.

System-model context metrics require iOS 26.4, macOS 26.4, Mac Catalyst 26.4, or visionOS 26.4. Counting failures and invalid metrics hide the Context section. Usage is available on OS 27 and reports session usage separately from context-window consumption. Attachments, reasoning, and other OS 27 diagnostics appear only when supported and present in the transcript.

## Export and feedback

Open the Export menu in the toolbar to copy or share the complete transcript as formatted JSON, including entries hidden by search. In the same menu, choose Report Feedback… to select sentiment and issues, add explanations, and describe the desired response. Share the resulting `LanguageModelFeedback` JSON from the feedback form with Feedback Assistant; this does not submit a report automatically.

## Topics

### Essentials

- ``TranscriptDebugMenu``
- ``SwiftUICore/View/transcriptDebugMenu(_:isPresented:configuration:)``
- ``TranscriptDebugMenu/Configuration``
- <doc:MigratingTo2.0>

### Context Metrics

- ``TranscriptDebugMenu/ContextMetrics``
- ``TranscriptDebugMenu/ContextMetricsProvider``

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Author

Artem Novichkov, https://artemnovichkov.com/

## License

The project is available under the MIT license. See the [LICENSE](./LICENSE) file for more info.

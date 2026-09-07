# Migrating to TranscriptDebugMenu 2.0

Adopt explicit model diagnostics and the Swift 6.4 toolchain.

## Overview

TranscriptDebugMenu 2.0 requires Xcode 27 and Swift 6.4. The deployment targets remain iOS 26, macOS 26, Mac Catalyst 26, and visionOS 26.

The transcript menu no longer assumes that every session uses `SystemLanguageModel.default`. Supply the model that created the session so token counts and context limits remain correct:

```swift
let model = SystemLanguageModel(useCase: .contentTagging)
let session = LanguageModelSession(model: model)

ContentView()
    .transcriptDebugMenu(
        session,
        isPresented: $showTranscript,
        configuration: .systemModel(model)
    )
```

For a custom or dynamically selected model, provide a ``TranscriptDebugMenu/ContextMetricsProvider``. If the model has no reliable token-count API, omit `configuration` or pass `TranscriptDebugMenu.Configuration()`; context progress stays hidden while the rest of the diagnostics remain available.

Both entry points now default to an empty configuration. `TranscriptDebugMenu(session: session)` and `.transcriptDebugMenu(session, isPresented: $showTranscript)` are supported without deprecation warnings. They display the transcript without context metrics and never assume a default model.

For direct presentation, use `TranscriptDebugMenu(session: session, configuration: .systemModel(model))`. Omit `configuration` when a compatible counter is unavailable.

System-model counting requires OS 26.4 or later. On OS 26.0–26.3, the menu still works but hides Context. On OS 27, Usage displays the session's reported input, cached input, output, and reasoning tokens independently of the configured context counter. OS 27-only fields are shown only when available and present.

TranscriptDebugMenu 2.0 also replaces the sentiment-only toolbar with a single Export menu. Use it to copy or share formatted transcript JSON, or choose Report Feedback… to open the detailed feedback composer.

The library no longer adds a retroactive `Hashable` conformance to `Transcript.Entry`. If your app relied on that conformance for navigation or collections, use entry IDs or an app-owned `Hashable` route type instead.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TranscriptDebugMenu is a SwiftUI library for inspecting `LanguageModelSession` transcripts in Apple Intelligence applications. It provides searchable entry details, model-specific context metrics, usage and metadata inspection, formatted JSON export, and detailed feedback for Apple's Feedback Assistant.

## Build and Development Commands

### Documentation
- **Build documentation**: `./build-docc.sh` - Generates static documentation site in `docs/` directory using Swift Package Manager's DocC plugin
- **Preview documentation**: `./preview-docc.sh` - Opens live preview of DocC documentation in Xcode

### Swift Package Manager
- **Build**: `swift build`
- **Test**: `swift test`
- **Clean**: `swift package clean`

### Xcode
- Open `Example/TranscriptDebugMenuExample.xcodeproj` to run the example app
- The library targets iOS 26+, macOS 26+, visionOS 26+, and macCatalyst 26+
- Requires Swift 6.4+ and Xcode 27.0

## Architecture

### Core Components

**TranscriptDebugMenu.swift** (`Sources/TranscriptDebugMenu/TranscriptDebugMenu.swift:41`)
- Main SwiftUI view that displays `LanguageModelSession` transcripts
- Features search functionality with scoped filtering by entry type
- Provides context menu for copying entries
- Displays explicitly configured, model-specific context-window metrics
- Exports formatted transcript JSON and generates complete `LanguageModelFeedback` JSON for Apple

**TranscriptEntryDetailView.swift** (`Sources/TranscriptDebugMenu/TranscriptEntryDetailView.swift:9`)
- Detail view for individual transcript entries
- Shows structured content for different entry types (instructions, prompts, tool calls, etc.)
- Displays individual entry token counts in navigation subtitle
- Provides copy functionality for detailed entry inspection

**TranscriptDebugMenu+Configuration.swift** (`Sources/TranscriptDebugMenu/TranscriptDebugMenu+Configuration.swift`)
- Defines the public `Configuration`, `ContextMetrics`, and `ContextMetricsProvider` API
- Uses `SystemLanguageModel.tokenCount(for:)` on iOS 26.4+ when a matching model is supplied
- Supports custom providers and intentionally hides context metrics when no reliable counter exists

**FeedbackView.swift** (`Sources/TranscriptDebugMenu/FeedbackView.swift`)
- Composes sentiment, issue categories, explanations, and a desired response
- Shares a regenerated `LanguageModelFeedback` attachment

**TokenCounter.swift** (`Sources/TranscriptDebugMenu/TokenCounter.swift`)
- Formats token counts and context-window percentages for display

**View+TranscriptDebugMenu.swift** (`Sources/TranscriptDebugMenu/View+TranscriptDebugMenu.swift:37`)
- SwiftUI view modifier that presents the debug menu as a sheet
- Primary API for integrating the library into SwiftUI apps

**SearchScope.swift** (`Sources/TranscriptDebugMenu/SearchScope.swift:5`)
- Enum defining filter scopes for transcript entries: all, instructions, prompt, response, toolCalls, toolOutput
- Uses emoji symbols for compact UI representation

### Key Dependencies
- **FoundationModels**: Core framework for `LanguageModelSession`, `Transcript.Entry`, and `LanguageModelFeedback`
- **SwiftUI**: UI framework
- **OSLog**: Logging for error handling
- **UIKit/AppKit**: Platform-specific clipboard operations

### Entry Points
- `.transcriptDebugMenu(session, isPresented:configuration:)` - Primary API for presenting the debug menu
- `TranscriptDebugMenu(session:configuration:)` - Direct view initialization
- Both entry points default to an empty configuration; omitting it hides context metrics without assuming `SystemLanguageModel.default`

## Development Patterns

### Search Implementation
The search functionality filters entries by type using `TranscriptFilter`, then searches IDs, text and structured segments, metadata, tool schemas and calls, attachment labels and URLs, options, responses, and reasoning.

### Token Counting
The host explicitly supplies the same model used by the session through `.systemModel(model)`, or supplies a custom `ContextMetricsProvider`. No default-model fallback is allowed. Provider errors, cancellation, and invalid values hide the metric rather than presenting misleading data.

### Cross-Platform Support
`DebugClipboard` uses conditional compilation (`#if canImport(UIKit)` / `#elseif canImport(AppKit)`) for clipboard operations across iOS/macOS platforms.

### Documentation
The project uses DocC for documentation with tutorials and code examples in `Sources/TranscriptDebugMenu/Documentation.docc/`.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TranscriptDebugMenu is a SwiftUI library for inspecting `LanguageModelSession` transcripts in Apple Intelligence applications. It provides a debug interface to view, search, and copy transcript entries, display approximate token counts, as well as generate feedback for Apple's Feedback Assistant.

## Build and Development Commands

### Documentation
- **Build documentation**: `./build-docc.sh` - Generates static documentation site in `docs/` directory using Swift Package Manager's DocC plugin
- **Preview documentation**: `./preview-docc.sh` - Opens live preview of DocC documentation in Xcode

### Swift Package Manager
- **Build**: `swift build`
- **Test**: `swift test` (if tests are added)
- **Clean**: `swift package clean`

### Xcode
- Open `Example/TranscriptDebugMenuExample.xcodeproj` to run the example app
- The library targets iOS 26+, macOS 26+, visionOS 26+, and macCatalyst 26+
- Requires Swift 6.2+ and Xcode 26.0 beta 5

## Architecture

### Core Components

**TranscriptDebugMenu.swift** (`Sources/TranscriptDebugMenu/TranscriptDebugMenu.swift:41`)
- Main SwiftUI view that displays `LanguageModelSession` transcripts
- Features search functionality with scoped filtering by entry type
- Provides context menu for copying entries
- Displays approximate token counts in navigation subtitle (~X tokens)
- Includes sentiment feedback (positive/negative) and generates `LanguageModelFeedback` JSON for Apple

**TranscriptEntryDetailView.swift** (`Sources/TranscriptDebugMenu/TranscriptEntryDetailView.swift:9`)
- Detail view for individual transcript entries
- Shows structured content for different entry types (instructions, prompts, tool calls, etc.)
- Displays individual entry token counts in navigation subtitle
- Provides copy functionality for detailed entry inspection

**Transcript+Tokens.swift** (`Sources/TranscriptDebugMenu/Transcript+Tokens.swift:7`)
- Extensions for calculating approximate token counts
- Implements character-based estimation using division by 4 (characters ÷ 4)
- Provides `tokensCount` computed properties for both `Transcript` and `Transcript.Entry`
- Handles all entry types: instructions, prompts, responses, tool calls, tool output

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
- `.transcriptDebugMenu(session, isPresented:)` - Primary API for presenting the debug menu
- `TranscriptDebugMenu(session:)` - Direct view initialization

## Development Patterns

### Search Implementation
The search functionality filters entries by type (using `SearchScope`) and then by text content. All filtering happens in the computed `entries` property.

### Token Counting
The library provides approximate token counting using a simple character-based estimation (characters ÷ 4). Token counts are displayed with a "~" prefix to indicate approximation and include proper singular/plural handling.

### Cross-Platform Support
Uses conditional compilation (`#if canImport(UIKit)` / `#elseif canImport(AppKit)`) for clipboard operations across iOS/macOS platforms.

### Documentation
The project uses DocC for documentation with tutorials and code examples in `Sources/TranscriptDebugMenu/Documentation.docc/`.
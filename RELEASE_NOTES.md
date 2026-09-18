# TranscriptDebugMenu 2.0.0

Inspect Foundation Models sessions with explicit model diagnostics, richer transcript details, JSON export, and a feedback composer.

## Changes

- Configure context metrics with the session's actual `SystemLanguageModel` or a custom asynchronous provider. Omitting configuration opens the menu without assuming a model or displaying context metrics.
- Inspect session usage, reasoning, attachments, tool metadata, and context options on OS 27 when available.
- Read entry content first. IDs and other technical identifiers are collapsed at the bottom; response schemas expand on demand.
- Copy or share the complete transcript JSON from one Export menu. Choose Report Feedback… to prepare a detailed attachment for Feedback Assistant.
- Search IDs, structured content, tool arguments, metadata, and attachment labels and URLs.
- Keep system-model diagnostic identity stable across SwiftUI updates and restore temporary exports when the menu reappears.
- Removed the `swift-docc-plugin` dependency. The package no longer has external dependencies.
- Updated example scenarios, migration guidance, tutorials, and light/dark screenshots.

## Requirements and migration

- Xcode 27 and Swift 6.4 are required to build the package.
- Deployment targets remain iOS 26, macOS 26, Mac Catalyst 26, and visionOS 26.
- System-model token counting requires OS 26.4 or later. Earlier supported versions hide context metrics.
- Usage and other OS 27 fields appear only when available.
- Calls without `configuration` remain supported, but no longer assume `SystemLanguageModel.default` for metrics.
- The retroactive `Hashable` conformance for `Transcript.Entry` has been removed. Use entry IDs or an app-owned route type instead.

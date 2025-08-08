# Repository Guidelines

## Project Structure & Modules
- Sources: `Sources/TranscriptDebugMenu/` contains the SwiftUI library (`TranscriptDebugMenu.swift`, `View+TranscriptDebugMenu.swift`, mocks).
- Docs: `docs/` hosts generated DocC static site; `build-docc.sh` and `preview-docc.sh` help build/preview.
- Config: `Package.swift` defines a single library target and DocC plugin. No test target currently.
- Assets: `.github/` contains screenshots used in the README.

## Build, Test, and Development
- Build (SwiftPM): `swift build` — builds the package locally.
- Xcode: Open the folder in Xcode 26.0 (beta 5) and build the SPM package target.
- Docs (static): `./build-docc.sh` — generates docs into `docs/` for static hosting.
- Docs (preview): `./preview-docc.sh` — launches DocC preview for local browsing.
- Tests: `swift test` — available once a test target is added.

## Coding Style & Naming
- Swift 6.2, 4‑space indentation; keep lines readable (~120 cols).
- Types/Protocols/Enums: UpperCamelCase (e.g., `TranscriptDebugMenu`).
- Methods/Variables/Case values: lowerCamelCase (e.g., `transcriptDebugMenu(...)`).
- File names match primary type or extension purpose (e.g., `View+TranscriptDebugMenu.swift`).
- Public API only where needed; follow Swift API Design Guidelines and platform availability in `Package.swift`.

## Testing Guidelines
- Location: `Tests/TranscriptDebugMenuTests/` (create if missing).
- Naming: `XxxTests.swift` with `test_...()` methods; focus on view modifiers and data formatting.
- Run: `swift test` from repo root; ensure tests are deterministic and avoid UI flakiness.
- Coverage: Prefer meaningful tests over numbers; add tests for public API and logic helpers.

## Commit & Pull Request Guidelines
- Commits: Imperative, concise subject (e.g., "Add feedback"), scope optional; group related changes.
- PRs: Include purpose, summary of changes, before/after screenshots for UI, steps to validate, and linked issues.
- CI: None configured; please run build and doc scripts locally before requesting review.

## Security & Configuration Tips
- Avoid logging sensitive transcript content; `OSLog` is used for errors only.
- Temporary files: feedback JSON is written to the system temp directory; clean up when appropriate.

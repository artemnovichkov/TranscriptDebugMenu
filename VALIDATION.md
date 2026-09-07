# Version 2.0 validation

## 2.0.0-beta.1 release validation — September 7, 2026

This section supersedes the preparation blockers recorded in the historical audits below.

- Fixed the example model lifetime: both the model and session now use `@State`, keeping the configured model instance aligned with the retained session across view reconstruction.
- Re-ran `swift test` after the fix: 16 tests passed, and the OS 27-only test was skipped on macOS 26.6.2.
- Rebuilt the example after the fix for generic iOS Simulator (arm64 and x86_64), deployment target iOS 26, with signing disabled. Build succeeded; only the expected missing-AppIntents metadata warning remained.
- Release package compilation and fresh DocC generation with `--warnings-as-errors` passed during the follow-up audit. The final fix affects only the example app, so the library and DocC results still apply.
- Excluded the local Codex configuration and example signing/bundle-identifier overrides from the release snapshot, preserving those settings locally. Included the documentation whitespace cleanup.
- README installation uses the exact `2.0.0-beta.1` tag. This is a prerelease; stable `1.6.8` remains available.

Known beta validation gaps: the iOS 27 test bundle compiled, but its run stalled before producing results. Real-device model generation/token counting, interactive navigation/sharing/feedback, and runtime coverage across all supported platforms remain unverified. See the follow-up audit for details.

## September 7, 2026 follow-up audit

This section supersedes the environment blockers in the earlier-session report below. No release was published and the Git index was not modified during this audit.

- `swift build -c release` succeeded.
- Xcode 27 / Swift 6.4 on macOS 26.6.2: `swift test` completed successfully. Sixteen tests passed; the OS 27-only test was skipped.
- The example built successfully for generic iOS Simulator (arm64 and x86_64), with deployment target iOS 26 and signing disabled. The only build warning was skipped App Intents metadata extraction because the app does not depend on AppIntents.
- The iOS 27 simulator test bundle compiled, but the `xcodebuild test` invocation then made no visible progress at `Resolve Package Graph` for several minutes and was stopped. No iOS test results were produced; the OS 27-only test remains unverified. Log: `/tmp/transcriptdebugmenu-release-audit-tests.log`.
- Fresh SwiftPM DocC generation succeeded with `--warnings-as-errors`, writing to `/tmp/transcriptdebugmenu-release-audit-docs` without replacing the checked-in site.
- All 872 checked-in documentation JSON files parse successfully. The privacy manifest and shared example scheme XML also parse successfully.
- `git ls-remote --tags origin` succeeded: the highest published tag is `1.6.8`; no `2.0` stable or prerelease tag exists at the time of this audit.
- The worktree passes `git diff --check`. The staged snapshot fails `git diff --cached --check` with 61 trailing-whitespace findings. The 870 documentation files that differ between index and worktree differ only in whitespace.

Code review finding:

- `ExampleSessionView.swift:51–64`: `ClassicSessionView` preserves its session with `@State`, but recreates its ordinary `let model` whenever the parent reconstructs the view. For `.contentTagging` and `.permissiveGuardrails`, `makeModel` constructs a new instance. The debug configuration can therefore reference a different model instance than the retained session and restart metrics unnecessarily. Preserve the model/session pair with a shared SwiftUI state lifetime. This is a source-level finding; the parent-reconstruction scenario was not exercised interactively.

Release preparation still needs attention:

- The index includes the local `.codex/config.toml` and example signing-team/bundle-identifier changes (`YGG8JTTV3J`, `com.artemnovichkov2.TranscriptDebugMenuExample`). Review/exclude those local settings before committing.
- Stage the final documentation whitespace cleanup and updated validation report before creating the release commit.
- The README stable `from: "2.0.0"` snippet cannot resolve until a stable tag exists; beta installation requires an exact published prerelease tag as explained above the snippet.
- Real-device generation/token counting and interactive navigation, clipboard, sharing, feedback editing/retry, and all-platform runtime checks remain unverified by this audit.

## September 7, 2026 earlier-session release audit

Status: release candidate prepared locally; Git index finalization, publication, and a fresh full test run remain blocked by the current environment.

- The example project built successfully after the final code fixes via Xcode, targeting arm64 iOS Simulator with deployment target iOS 26.0, Xcode 27, and Swift 6.4.
- Earlier in this session, `swift test` passed 15 tests and skipped one OS 27-only test on macOS 26. The final suite now contains 17 tests, including a new regression test for system-model provider identity; it has **not** been rerun successfully after the final changes.
- SwiftPM test and documentation commands now fail at manifest execution because the nested sandbox cannot be created. Switching to the package test scheme through Xcode was rejected because the tool requires approval and the session policy is `never`.
- Documentation was regenerated from the final Xcode-built module using `swift-symbolgraph-extract -emit-extension-block-symbols` and `docc convert --warnings-as-errors`. The generated `docs/` site has 872 valid JSON files; primary API/migration/tutorial pages and image references passed checks. The removed modifier overload page is absent.
- Prompt previews rendered on iOS 27 in light and dark appearance; the basic Prompt was also checked at accessibility Dynamic Type AX 3. Transcript previews show the single Export toolbar button. Updated screenshots are included in README and DocC resources.
- Fixed repeated system-model diagnostic refreshes by identifying the provider with the actual model instance. Custom providers retain distinct identities.
- Restored export generation on menu appearance so temporary files removed on disappearance are recreated on return.
- Documented optional configuration, the removal of the retroactive `Transcript.Entry: Hashable` conformance, and exact-tag installation for betas.
- Privacy manifest and shared example scheme XML parse successfully. `git diff --check` passed.
- Initial staging succeeded, but subsequent Git index updates failed with `Operation not permitted` creating `.git/index.lock`. The index still includes local `.codex/config.toml` and example signing/bundle-identifier changes; exclude those local settings before committing. The worktree contains the newest validation report and generated-file whitespace cleanup.
- GitHub CLI and Git remote queries failed because GitHub could not be reached/resolved. The next available beta tag cannot be verified from this environment. Do not publish a guessed tag or describe this candidate as fully runtime-validated.

Before publishing: rerun the complete tests, verify the current remote beta tags, review the runtime gaps below, and publish the checked commit as a GitHub prerelease. `RELEASE_NOTES.md` contains the prepared release text.

## Previous validation

Checked on September 5, 2026 with Xcode 27 / Swift 6.4, macOS 26.5.2, and iPhone 17 Pro previews on iOS 27.

## Completed

- `swift test`: 15 tests passed; the OS 27-only search test was skipped on macOS 26.5.2. Coverage includes transcript JSON, structured search, scopes, provider errors/cancellation, metric validation, changed diagnostic requests, and feedback drafts.
- All four tutorial examples compiled in the package's test target, with only their `ContentView` types renamed to avoid collisions. The temporary compilation fixture was removed afterwards.
- The example app built successfully through Xcode for the iOS Simulator with deployment target iOS 26. The build's App Intents metadata warning is expected because the app has no App Intents dependency.
- SwiftUI previews rendered and were visually inspected for the transcript, prompt details, feedback, empty state, and an image attachment on iOS 27. Light/dark variants were checked for transcript, prompt details, and feedback. Prompt details were also checked with accessibility Dynamic Type AX 3.
- README and DocC screenshots now use the current UI with sample data. Tutorial screenshots are illustrative; generation output and token counts vary.
- `./build-docc.sh` rebuilt the static site without DocC warnings. Four primary DocC pages, their local page/image references, and all four embedded code snapshots were checked against source files.
- `git diff --check` passed.

## Fixes

- Export and feedback files refresh independently of asynchronous token counting and use atomic writes.
- Diagnostics restart when entry contents or the configured provider change. Old metrics clear during refresh; a cancelled task cannot clear newer results when its provider throws another error.
- The context progress bar clamps its visual range while the label preserves actual over-limit consumption.
- Feedback saving failures show an explanation and Retry instead of an indefinite spinner.
- Entry rows have a full rectangular tap area. Empty transcripts omit the empty section header, and the empty-state overlay doesn't cover an active generation indicator.
- The Session section no longer displays an absent error policy as `nil`.

## Remaining runtime checks

The following are not certified by the checks above:

- Interactive navigation, typing/search, clipboard actions, share-sheet contents, feedback edits/retry, and closing/reopening the menu while generation is active.
- Real model generation/token counting, including failure and cancellation, on Apple Intelligence hardware.
- Running the OS 27-only unit test, and runtime coverage on OS 26.0–26.3, Mac Catalyst, macOS UI, visionOS, and iPad.
- Browser rendering/navigation of the generated static site.

Direct CoreSimulator access and local HTTP serving were blocked by the execution sandbox. Xcode's interaction workflow required an unavailable `device-interaction` skill, so screenshots came from SwiftUI Preview rather than an interactive session. Switching Xcode schemes required approval unavailable under the current policy, preventing broader platform/test runs. No release or website was published.

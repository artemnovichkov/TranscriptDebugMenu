#!/bin/sh

set -e

# Build with Xcode for iOS: the SwiftPM plugin only builds for the host (macOS),
# which drops iOS, iPadOS, and Mac Catalyst availability from the generated site.

export DOCC_JSON_PRETTYPRINT="YES"

DERIVED_DATA=$(mktemp -d)
trap 'rm -rf "$DERIVED_DATA"' EXIT

xcodebuild docbuild \
    -scheme TranscriptDebugMenu \
    -destination "generic/platform=iOS" \
    -derivedDataPath "$DERIVED_DATA" \
    OTHER_DOCC_FLAGS="--warnings-as-errors" \
    -quiet

rm -rf docs
xcrun docc process-archive transform-for-static-hosting \
    "$DERIVED_DATA/Build/Products/Debug-iphoneos/TranscriptDebugMenu.doccarchive" \
    --hosting-base-path TranscriptDebugMenu \
    --output-path docs

echo '<script>window.location.href += "/documentation/transcriptdebugmenu"</script>' > docs/index.html

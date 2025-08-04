##!/bin/sh

export DOCC_JSON_PRETTYPRINT="YES"

swift package --allow-writing-to-directory docs \
    generate-documentation --target TranscriptDebugMenu \
    --output-path docs

echo '<script>window.location.href += "/documentation/transcriptdebugmenu"</script>' > docs/index.html
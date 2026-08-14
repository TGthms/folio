#!/bin/zsh
set -euo pipefail
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-/var/folders/x2/qy1z2cjd72b0ftthc7v66ryc0000gn/T/grok-goal-94ad10462006/implementer/fixtures}"
mkdir -p "$OUT"
BIN="$OUT/verify-export-paths"
xcrun swiftc -parse-as-library -O -framework PDFKit -framework AppKit \
  -o "$BIN" \
  "$ROOT/Folio/Models/PageRef.swift" \
  "$ROOT/Folio/Models/ExportOptions.swift" \
  "$ROOT/Folio/Services/PDFPageGraphics.swift" \
  "$ROOT/Folio/Services/RedactService.swift" \
  "$ROOT/Folio/Services/TextService.swift" \
  "$ROOT/scripts/verify-export-paths.swift"
"$BIN" "$OUT"
# Protect via the shipped PDFIO.write (not a reimplementation).
"$ROOT/scripts/run-protect-write-driver.sh" "$OUT"

#!/bin/zsh
set -euo pipefail
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/build/protect-write-out}"
BIN="$ROOT/build/protect-write-driver"
mkdir -p "$OUT" "$(dirname "$BIN")"
need_compile=1
if [[ -x "$BIN" ]]; then
  newest_src=$(ls -t \
    "$ROOT/Folio/Models/FolioError.swift" \
    "$ROOT/Folio/Models/ExportOptions.swift" \
    "$ROOT/Folio/Models/PageMark.swift" \
    "$ROOT/Folio/Models/Tool.swift" \
    "$ROOT/Folio/Models/PageRef.swift" \
    "$ROOT/Folio/Services/PDFPageGraphics.swift" \
    "$ROOT/Folio/Services/PDFIO.swift" \
    "$ROOT/scripts/protect-write-driver.swift" | head -n 1)
  if [[ "$BIN" -nt "$newest_src" ]]; then
    need_compile=0
  fi
fi
if [[ "$need_compile" -eq 1 ]]; then
  xcrun swiftc -parse-as-library -O -framework PDFKit -framework AppKit \
    -o "$BIN" \
    "$ROOT/Folio/Models/FolioError.swift" \
    "$ROOT/Folio/Models/ExportOptions.swift" \
    "$ROOT/Folio/Models/PageMark.swift" \
    "$ROOT/Folio/Models/Tool.swift" \
    "$ROOT/Folio/Models/PageRef.swift" \
    "$ROOT/Folio/Services/PDFPageGraphics.swift" \
    "$ROOT/Folio/Services/PDFIO.swift" \
    "$ROOT/scripts/protect-write-driver.swift"
fi
"$BIN" "$OUT"

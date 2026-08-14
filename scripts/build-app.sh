#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$ROOT"
python3 scripts/generate_strings.py
python3 scripts/generate_xcodeproj.py
DEST="$ROOT/build"
mkdir -p "$DEST"
xcodebuild \
  -project Folio.xcodeproj \
  -scheme Folio \
  -configuration Release \
  -derivedDataPath "$DEST/DerivedData" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  build
APP=$(find "$DEST/DerivedData/Build/Products" -name 'Folio.app' -maxdepth 3 | head -n 1)
if [[ -z "$APP" ]]; then
  echo "Folio.app not found" >&2
  exit 1
fi
rm -rf "$DEST/Folio.app"
cp -R "$APP" "$DEST/Folio.app"
echo "Built $DEST/Folio.app"

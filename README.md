# Folio

[English](README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md)

**Folio** is a local-only macOS PDF toolbox published by **TGthms**. Pages live in one workspace. Tools are modes over that workspace. Files never leave this Mac. Export never overwrites an original unless you confirm.

Requires macOS 15+ and Xcode 16 / 26 to build.

## Product

Drop PDFs or images into a single workspace, arrange pages, pick a job, then export.

- Merge, split / extract, rotate, reorder, delete
- Compress
- Watermark and page numbers
- Images ↔ PDF
- Protect and unlock
- Extract text and OCR
- True redaction (redacted pages are rasterized)
- Read mode scrolls every page in the workspace
- 30 interface languages, including RTL; language follows macOS
- Sandboxed. No network entitlement. Work stays on this computer.

The running app is named **Folio**. This repository is **TGthms**.

## Build

Open the project in Xcode:

```
open Folio.xcodeproj
```

Or build the app from the terminal:

```
./scripts/build-app.sh
open build/Folio.app
```

The script regenerates `Folio.xcodeproj` and the string catalog, then produces `build/Folio.app`.

## Use

Drop PDFs or images onto the window. Arrange pages, pick a job in the sidebar, then **Export…**.

- `⌘O` add files · `⌘S` export · `⌘P` print
- `⌘1` Pages · `⌘2` Read (scrolls the whole workspace)
- `⌘]` / `⌘[` next / previous page · `⌥⌘↑` / `⌥⌘↓` first / last
- arrows, `j`/`k`, Page Up/Down, Home/End
- `⌘R` / `⇧⌘R` rotate · `⌘⌫` remove from workspace · `⌘A` select all pages
- `⌘I` inspector · `⌘K` command palette · `⌘Z` undo

Language follows **System Settings → Language & Region**. Override it in Settings; it applies on the next launch.

## Tests

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Folio.xcodeproj -scheme Folio -destination 'platform=macOS' test
./scripts/verify-export-paths.sh
```

`scripts/run-protect-write-driver.sh` compiles shipped `PDFIO.swift` into `build/protect-write-driver` and writes a passworded PDF. `FolioLogicTests` execs that driver — PDFKit encrypt deadlocks inside the Folio.app XCTest host, so protect is not run in-process there.

## License

[MIT](LICENSE) © 2026 TGthms

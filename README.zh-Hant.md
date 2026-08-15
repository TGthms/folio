# Folio

[English](README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md)

**Folio** 是 **TGthms** 發布的本機 macOS PDF 工具箱。所有頁面放在同一個工作區，每個工具都是這個工作區上的一種模式。檔案不會離開這台 Mac。除非你確認，匯出不會覆寫原檔。

需要 macOS 15+，用 Xcode 16 / 26 建置。

## 產品

把 PDF 或圖片拖進一個工作區，整理頁面，選擇工作，然後匯出。

- 合併、分割 / 擷取、旋轉、重排、刪除
- 壓縮
- 浮水印與頁碼
- 圖片 ↔ PDF
- 加密與解鎖
- 擷取文字與 OCR
- 真正的塗黑（被塗黑的頁面會點陣化）
- 編輯：反白、底線、文字框、繪製、裁剪、用影像取代頁面。儲存 / 匯出時寫入頁面。不會改寫 PDF 裡既有的文字。
- 閱讀模式可捲動工作區中的每一頁
- 30 種介面語言（含由右至左）；語言跟隨系統
- 沙盒執行，無網路權限。處理只在本機完成。

執行中的應用程式名叫 **Folio**。本儲存庫名為 **[folio](https://github.com/TGthms/folio)**。

## 建置

在 Xcode 中開啟專案：

```
open Folio.xcodeproj
```

或在終端機建置應用程式：

```
./scripts/build-app.sh
open build/Folio.app
```

腳本會重新產生 `Folio.xcodeproj` 與字串目錄，並產出 `build/Folio.app`。

## 使用

把 PDF 或圖片拖到視窗上。整理頁面，在側邊欄選擇工作，然後按 **Export…**。

- `⌘O` 加入檔案 · `⌘S` 儲存 · `⇧⌘S` 匯出 · `⌘P` 列印
- `⌘1` 頁面 · `⌘2` 閱讀（捲動整個工作區）
- `⌘]` / `⌘[` 下一頁 / 上一頁 · `⌥⌘↑` / `⌥⌘↓` 首頁 / 末頁
- 方向鍵、`j`/`k`、Page Up/Down、Home/End
- `⌘R` / `⇧⌘R` 旋轉 · `⌘⌫` 從工作區移除 · `⌘A` 全選頁面
- `⌘I` 檢查器 · `⌘K` 命令面板 · `⌘Z` 復原

語言跟隨 **系統設定 → 語言與地區**。可在設定中覆寫，選擇後立即生效。

## 測試

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Folio.xcodeproj -scheme Folio -destination 'platform=macOS' test
./scripts/verify-export-paths.sh
```

## 授權

[MIT](LICENSE) © 2026 TGthms

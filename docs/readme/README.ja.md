# Folio

[English](../../README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md)

**Folio** は **TGthms** が公開する、Mac 上だけで動く PDF ツールです。ページはひとつのワークスペースに集まり、各ツールはそのワークスペースに対するモードです。ファイルはこの Mac から出ません。確認しない限り、書き出しは元のファイルを上書きしません。

ビルドには macOS 15 以降と Xcode 16 / 26 が必要です。

## 製品

PDF や画像をひとつのワークスペースにドロップし、ページを整えて作業を選び、書き出します。

- 結合、分割 / 抽出、回転、並べ替え、削除
- 圧縮
- 透かしとページ番号
- 画像 ↔ PDF
- 保護と解除
- テキスト抽出と OCR
- 本格的な墨消し（対象ページはラスタライズされます）
- 編集：ハイライト、下線、テキストボックス、描画、トリミング、画像でページを置き換え。保存 / 書き出し時にページへ焼き込みます。既存の PDF テキストは書き換えません。
- 閲覧モードではワークスペースの全ページをスクロールできます
- 30 のインターフェース言語（RTL を含む）。言語は macOS に従います
- サンドボックス。ネットワーク権限なし。処理はこのコンピュータ上だけです。

実行中のアプリ名は **Folio** です。このリポジトリ名は **[folio](https://github.com/TGthms/folio)** です。

## ビルド

Xcode でプロジェクトを開きます：

```
open Folio.xcodeproj
```

またはターミナルからアプリをビルドします：

```
./scripts/build-app.sh
open build/Folio.app
```

スクリプトは `Folio.xcodeproj` と文字列カタログを再生成し、`build/Folio.app` を作ります。

## 使い方

PDF や画像をウィンドウにドロップします。ページを整え、サイドバーで作業を選び、**Export…** します。

- `⌘O` ファイルを追加 · `⌘S` 保存 · `⇧⌘S` 書き出し · `⌘P` 印刷
- `⌘1` ページ · `⌘2` 閲覧（ワークスペース全体をスクロール）
- `⌘]` / `⌘[` 次 / 前のページ · `⌥⌘↑` / `⌥⌘↓` 最初 / 最後
- 矢印、`j`/`k`、Page Up/Down、Home/End
- `⌘R` / `⇧⌘R` 回転 · `⌘⌫` ワークスペースから削除 · `⌘A` 全ページ選択
- `⌘I` インスペクタ · `⌘K` コマンドパレット · `⌘Z` 取り消し

言語は **システム設定 → 言語と地域** に従います。設定で上書きでき、選ぶとすぐに切り替わります。

## テスト

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Folio.xcodeproj -scheme Folio -destination 'platform=macOS' test
./scripts/verify-export-paths.sh
```

## ライセンス

[MIT](../../LICENSE) © 2026 TGthms

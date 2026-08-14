# Folio

[English](README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md)

**Folio** 是 **TGthms** 发布的本地 macOS PDF 工具箱。所有页面放在同一个工作区，每个工具都是这个工作区上的一种模式。文件不会离开这台 Mac。除非你确认，导出不会覆盖原文件。

需要 macOS 15+，用 Xcode 16 / 26 构建。

## 产品

把 PDF 或图片拖进一个工作区，整理页面，选择任务，然后导出。

- 合并、拆分 / 提取、旋转、重排、删除
- 压缩
- 水印和页码
- 图片 ↔ PDF
- 加密与解锁
- 提取文本和 OCR
- 真正的涂黑（被涂黑的页面会栅格化）
- 阅读模式可滚动工作区中的每一页
- 30 种界面语言（含从右到左）；语言跟随系统
- 沙盒运行，无网络权限。处理只在本机完成。

运行中的应用名叫 **Folio**。本仓库名为 **[folio](https://github.com/TGthms/folio)**。

## 构建

在 Xcode 中打开项目：

```
open Folio.xcodeproj
```

或在终端构建应用：

```
./scripts/build-app.sh
open build/Folio.app
```

脚本会重新生成 `Folio.xcodeproj` 和字符串目录，并产出 `build/Folio.app`。

## 使用

把 PDF 或图片拖到窗口上。整理页面，在侧栏选择任务，然后点 **Export…**。

- `⌘O` 添加文件 · `⌘S` 导出 · `⌘P` 打印
- `⌘1` 页面 · `⌘2` 阅读（滚动整个工作区）
- `⌘]` / `⌘[` 下一页 / 上一页 · `⌥⌘↑` / `⌥⌘↓` 首页 / 末页
- 方向键、`j`/`k`、Page Up/Down、Home/End
- `⌘R` / `⇧⌘R` 旋转 · `⌘⌫` 从工作区移除 · `⌘A` 全选页面
- `⌘I` 检查器 · `⌘K` 命令面板 · `⌘Z` 撤销

语言跟随 **系统设置 → 语言与地区**。可在设置中覆盖，下次启动生效。

## 测试

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Folio.xcodeproj -scheme Folio -destination 'platform=macOS' test
./scripts/verify-export-paths.sh
```

## 许可

[MIT](LICENSE) © 2026 TGthms

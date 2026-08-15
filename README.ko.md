# Folio

[English](README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md)

**Folio**는 **TGthms**가 공개하는 로컬 전용 macOS PDF 도구입니다. 페이지는 하나의 작업 공간에 모이고, 각 도구는 그 작업 공간에 대한 모드입니다. 파일은 이 Mac을 떠나지 않습니다. 확인하지 않으면 내보내기는 원본을 덮어쓰지 않습니다.

빌드하려면 macOS 15 이상과 Xcode 16 / 26이 필요합니다.

## 제품

PDF나 이미지를 하나의 작업 공간에 놓고, 페이지를 정리한 뒤 작업을 골라 내보냅니다.

- 병합, 분할 / 추출, 회전, 재정렬, 삭제
- 압축
- 워터마크와 쪽 번호
- 이미지 ↔ PDF
- 보호와 잠금 해제
- 텍스트 추출과 OCR
- 실제 레닥션(가린 페이지는 래스터화됩니다)
- 편집: 강조, 밑줄, 텍스트 상자, 그리기, 자르기, 이미지로 페이지 바꾸기. 저장 / 내보내기 때 페이지에 구워집니다. 기존 PDF 텍스트는 다시 쓰지 않습니다.
- 읽기 모드에서는 작업 공간의 모든 페이지를 스크롤합니다
- 인터페이스 언어 30개(RTL 포함). 언어는 macOS를 따릅니다
- 샌드박스. 네트워크 권한 없음. 작업은 이 컴퓨터에서만 이루어집니다.

실행 중인 앱 이름은 **Folio**입니다. 이 저장소 이름은 **[folio](https://github.com/TGthms/folio)**입니다.

## 빌드

Xcode에서 프로젝트를 엽니다:

```
open Folio.xcodeproj
```

또는 터미널에서 앱을 빌드합니다:

```
./scripts/build-app.sh
open build/Folio.app
```

스크립트는 `Folio.xcodeproj`와 문자열 카탈로그를 다시 만들고 `build/Folio.app`을 만듭니다.

## 사용

PDF나 이미지를 창에 놓습니다. 페이지를 정리하고 사이드바에서 작업을 고른 다음 **Export…** 합니다.

- `⌘O` 파일 추가 · `⌘S` 저장 · `⇧⌘S` 내보내기 · `⌘P` 인쇄
- `⌘1` 페이지 · `⌘2` 읽기(작업 공간 전체 스크롤)
- `⌘]` / `⌘[` 다음 / 이전 페이지 · `⌥⌘↑` / `⌥⌘↓` 처음 / 마지막
- 화살표, `j`/`k`, Page Up/Down, Home/End
- `⌘R` / `⇧⌘R` 회전 · `⌘⌫` 작업 공간에서 제거 · `⌘A` 모든 페이지 선택
- `⌘I` 검사기 · `⌘K` 명령 팔레트 · `⌘Z` 실행 취소

언어는 **시스템 설정 → 언어 및 지역**을 따릅니다. 설정에서 바꿀 수 있으며 고르면 바로 바뀝니다.

## 테스트

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Folio.xcodeproj -scheme Folio -destination 'platform=macOS' test
./scripts/verify-export-paths.sh
```

## 라이선스

[MIT](LICENSE) © 2026 TGthms

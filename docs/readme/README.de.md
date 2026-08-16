# Folio

[English](../../README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md)

**Folio** ist eine ausschließlich lokale macOS-PDF-Werkzeugkiste von **TGthms**. Seiten leben in einem Arbeitsbereich. Jedes Werkzeug ist ein Modus über diesem Arbeitsbereich. Dateien verlassen diesen Mac nicht. Ein Export überschreibt ein Original nur nach Bestätigung.

Zum Bauen werden macOS 15+ und Xcode 16 / 26 benötigt.

## Produkt

Ziehen Sie PDFs oder Bilder in einen Arbeitsbereich, ordnen Sie Seiten, wählen Sie eine Aufgabe und exportieren Sie.

- Zusammenführen, teilen / extrahieren, drehen, umordnen, löschen
- Komprimieren
- Wasserzeichen und Seitenzahlen
- Bilder ↔ PDF
- Schützen und entsperren
- Text extrahieren und OCR
- Echte Schwärzung (geschwärzte Seiten werden gerastert)
- Bearbeiten: Hervorheben, Unterstreichen, Textfeld, Zeichnen, Zuschneiden, Seite durch Bild ersetzen. Markierungen werden beim Sichern / Export eingebrannt. Vorhandener PDF-Text wird nicht umgeschrieben.
- Der Lesemodus scrollt durch alle Seiten im Arbeitsbereich
- 30 Oberflächensprachen, einschließlich RTL; die Sprache folgt macOS
- Sandbox. Keine Netzwerkberechtigung. Die Arbeit bleibt auf diesem Rechner.

Die laufende App heißt **Folio**. Dieses Repository heißt **[folio](https://github.com/TGthms/folio)**.

## Bauen

Projekt in Xcode öffnen:

```
open Folio.xcodeproj
```

Oder die App im Terminal bauen:

```
./scripts/build-app.sh
open build/Folio.app
```

Das Skript erzeugt `Folio.xcodeproj` und den String-Katalog neu und schreibt `build/Folio.app`.

## Nutzen

Ziehen Sie PDFs oder Bilder auf das Fenster. Ordnen Sie Seiten, wählen Sie eine Aufgabe in der Seitenleiste und dann **Export…**.

- `⌘O` Dateien hinzufügen · `⌘S` sichern · `⇧⌘S` exportieren · `⌘P` drucken
- `⌘1` Seiten · `⌘2` Lesen (scrollt den ganzen Arbeitsbereich)
- `⌘]` / `⌘[` nächste / vorherige Seite · `⌥⌘↑` / `⌥⌘↓` erste / letzte
- Pfeiltasten, `j`/`k`, Page Up/Down, Home/End
- `⌘R` / `⇧⌘R` drehen · `⌘⌫` aus dem Arbeitsbereich entfernen · `⌘A` alle Seiten
- `⌘I` Inspektor · `⌘K` Befehlspalette · `⌘Z` rückgängig

Die Sprache folgt **Systemeinstellungen → Sprache & Region**. Sie können sie in den Einstellungen überschreiben; die Oberfläche wechselt sofort.

## Tests

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Folio.xcodeproj -scheme Folio -destination 'platform=macOS' test
./scripts/verify-export-paths.sh
```

## Lizenz

[MIT](../../LICENSE) © 2026 TGthms

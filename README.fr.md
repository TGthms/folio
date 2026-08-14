# Folio

[English](README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md)

**Folio** est une boîte à outils PDF macOS entièrement locale, publiée par **TGthms**. Les pages vivent dans un seul espace de travail. Chaque outil est un mode sur cet espace. Les fichiers ne quittent pas ce Mac. L’export n’écrase un original que si vous le confirmez.

Nécessite macOS 15+ et Xcode 16 / 26 pour compiler.

## Produit

Déposez des PDF ou des images dans un seul espace de travail, organisez les pages, choisissez une tâche, puis exportez.

- Fusionner, scinder / extraire, faire pivoter, réordonner, supprimer
- Compresser
- Filigrane et numéros de page
- Images ↔ PDF
- Protéger et déverrouiller
- Extraire le texte et OCR
- Rédaction réelle (les pages caviardées sont rastérisées)
- Le mode Lecture fait défiler toutes les pages de l’espace de travail
- 30 langues d’interface, RTL compris ; la langue suit macOS
- Sandbox. Aucun droit réseau. Le travail reste sur cet ordinateur.

L’application s’appelle **Folio**. Ce dépôt s’appelle **[folio](https://github.com/TGthms/folio)**.

## Compiler

Ouvrez le projet dans Xcode :

```
open Folio.xcodeproj
```

Ou compilez l’application depuis le terminal :

```
./scripts/build-app.sh
open build/Folio.app
```

Le script régénère `Folio.xcodeproj` et le catalogue de chaînes, puis produit `build/Folio.app`.

## Utiliser

Déposez des PDF ou des images sur la fenêtre. Organisez les pages, choisissez une tâche dans la barre latérale, puis **Export…**.

- `⌘O` ajouter des fichiers · `⌘S` exporter · `⌘P` imprimer
- `⌘1` Pages · `⌘2` Lecture (fait défiler tout l’espace de travail)
- `⌘]` / `⌘[` page suivante / précédente · `⌥⌘↑` / `⌥⌘↓` première / dernière
- flèches, `j`/`k`, Page Up/Down, Home/End
- `⌘R` / `⇧⌘R` pivoter · `⌘⌫` retirer de l’espace de travail · `⌘A` tout sélectionner
- `⌘I` inspecteur · `⌘K` palette de commandes · `⌘Z` annuler

La langue suit **Réglages Système → Langue et région**. Vous pouvez la remplacer dans les réglages ; cela s’applique au prochain lancement.

## Tests

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Folio.xcodeproj -scheme Folio -destination 'platform=macOS' test
./scripts/verify-export-paths.sh
```

## Licence

[MIT](LICENSE) © 2026 TGthms

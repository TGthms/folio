# Folio

[English](README.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Español](README.es.md)

**Folio** es una caja de herramientas PDF para macOS que funciona solo en local, publicada por **TGthms**. Las páginas viven en un solo espacio de trabajo. Cada herramienta es un modo sobre ese espacio. Los archivos no salen de este Mac. La exportación no sobrescribe un original salvo que lo confirmes.

Requiere macOS 15+ y Xcode 16 / 26 para compilar.

## Producto

Suelta PDFs o imágenes en un espacio de trabajo, ordena las páginas, elige un trabajo y exporta.

- Combinar, dividir / extraer, rotar, reordenar, eliminar
- Comprimir
- Marca de agua y números de página
- Imágenes ↔ PDF
- Proteger y desbloquear
- Extraer texto y OCR
- Redacción real (las páginas tachadas se rasterizan)
- Editar: resaltar, subrayar, cuadro de texto, dibujar, recortar, reemplazar una página por una imagen. Las marcas se queman al guardar / exportar. El texto PDF existente no se reescribe.
- El modo Lectura recorre todas las páginas del espacio de trabajo
- 30 idiomas de interfaz, RTL incluido; el idioma sigue a macOS
- Entorno aislado. Sin permiso de red. El trabajo se queda en este ordenador.

La aplicación se llama **Folio**. Este repositorio se llama **[folio](https://github.com/TGthms/folio)**.

## Compilar

Abre el proyecto en Xcode:

```
open Folio.xcodeproj
```

O compila la aplicación desde el terminal:

```
./scripts/build-app.sh
open build/Folio.app
```

El script regenera `Folio.xcodeproj` y el catálogo de cadenas, y produce `build/Folio.app`.

## Usar

Suelta PDFs o imágenes en la ventana. Ordena las páginas, elige un trabajo en la barra lateral y pulsa **Export…**.

- `⌘O` añadir archivos · `⌘S` guardar · `⇧⌘S` exportar · `⌘P` imprimir
- `⌘1` Páginas · `⌘2` Lectura (recorre todo el espacio de trabajo)
- `⌘]` / `⌘[` página siguiente / anterior · `⌥⌘↑` / `⌥⌘↓` primera / última
- flechas, `j`/`k`, Page Up/Down, Home/End
- `⌘R` / `⇧⌘R` rotar · `⌘⌫` quitar del espacio de trabajo · `⌘A` seleccionar todas
- `⌘I` inspector · `⌘K` paleta de comandos · `⌘Z` deshacer

El idioma sigue **Ajustes del Sistema → Idioma y región**. Puedes cambiarlo en Ajustes; la interfaz cambia al momento.

## Pruebas

```
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -project Folio.xcodeproj -scheme Folio -destination 'platform=macOS' test
./scripts/verify-export-paths.sh
```

## Licencia

[MIT](LICENSE) © 2026 TGthms

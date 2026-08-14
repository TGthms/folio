#!/usr/bin/env python3
"""Write Folio/Localization/Localizable.xcstrings for every shipped locale."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Folio" / "Localization" / "Localizable.xcstrings"

LOCALES = [
    "en", "es", "fr", "de", "it", "pt-BR", "pt-PT", "nl", "da", "sv", "nb", "fi",
    "pl", "cs", "hu", "ro", "el", "tr", "ru", "uk", "ar", "he", "hi", "th", "vi",
    "id", "ja", "ko", "zh-Hans", "zh-Hant",
]

# key -> locale -> value
EN = {
    "app.name": "Folio",
    "group.organize": "Organize",
    "group.reduce": "Reduce",
    "group.stamp": "Stamp",
    "group.convert": "Convert",
    "group.secure": "Secure",
    "recents": "Recents",
    "recents.clear": "Clear",
    "recents.empty": "No recent files",
    "tool.pages": "Pages",
    "tool.merge": "Merge",
    "tool.split": "Split",
    "tool.compress": "Compress",
    "tool.watermark": "Watermark",
    "tool.pageNumbers": "Page numbers",
    "tool.imagesToPDF": "Images to PDF",
    "tool.pdfToImages": "PDF to images",
    "tool.extractText": "Extract text",
    "tool.ocr": "OCR",
    "tool.protect": "Protect",
    "tool.unlock": "Unlock",
    "tool.redact": "Redact",
    "stage.pages": "Pages",
    "stage.read": "Read",
    "toolbar.rotate": "Rotate right",
    "toolbar.rotateCCW": "Rotate left",
    "toolbar.delete": "Remove from workspace",
    "toolbar.addFiles": "Add files",
    "toolbar.inspector": "Inspector",
    "toolbar.settings": "Settings",
    "empty.headline": "Drop a PDF",
    "empty.hint": "Files stay on this Mac. Export never overwrites the original unless you ask.",
    "empty.drop": "Drop PDFs or images, or click to choose",
    "export": "Export…",
    "export.saved": "Saved",
    "export.replace": "Replace original",
    "export.replaceConfirm": "Replace the original file?",
    "export.replaceMessage": "This cannot be undone from Folio.",
    "export.flatten": "Flatten annotations",
    "inspector.pages": "Pages",
    "inspector.size": "Size",
    "inspector.document": "Document",
    "compress.after": "After",
    "compress.before": "Before",
    "compress.preset": "Preset",
    "compress.small": "Small (email)",
    "compress.medium": "Medium",
    "compress.high": "High quality",
    "compress.grayscale": "Grayscale",
    "split.mode": "Split",
    "split.selected": "Selected pages",
    "split.ranges": "Ranges",
    "split.rangesHint": "1-3, 7, 10-",
    "split.every": "Every N pages",
    "split.eachPage": "Each page",
    "split.oneFilePerRange": "One file per range",
    "merge.help": "Arrange pages in the tray, then export one file.",
    "watermark.text": "Watermark text",
    "watermark.position": "Position",
    "watermark.position.center": "Center",
    "watermark.position.tile": "Tile",
    "watermark.position.topLeft": "Top left",
    "watermark.position.topRight": "Top right",
    "watermark.position.bottomLeft": "Bottom left",
    "watermark.position.bottomRight": "Bottom right",
    "watermark.opacity": "Opacity",
    "watermark.rotation": "Rotation",
    "pageNumbers.format": "Format",
    "pageNumbers.format.number": "1",
    "pageNumbers.format.of": "1 / N",
    "pageNumbers.format.page": "Page 1",
    "pageNumbers.position": "Position",
    "pageNumbers.position.headerLeft": "Header left",
    "pageNumbers.position.headerCenter": "Header center",
    "pageNumbers.position.headerRight": "Header right",
    "pageNumbers.position.footerLeft": "Footer left",
    "pageNumbers.position.footerCenter": "Footer center",
    "pageNumbers.position.footerRight": "Footer right",
    "pageNumbers.startAt": "Start at",
    "pageNumbers.skipFirst": "Skip first page",
    "images.pageSize": "Page size",
    "images.pageSize.imageSize": "Image size",
    "images.pageSize.letter": "Letter",
    "images.pageSize.a4": "A4",
    "images.format": "Format",
    "images.dpi": "DPI",
    "extract.help": "Export the text layer of these pages as a .txt file.",
    "ocr.help": "Recognize text on scanned pages and write a searchable PDF. On this Mac only.",
    "unlock.help": "Write an unlocked copy. Folio needs the password you used when opening the file.",
    "protect.password": "Password",
    "protect.confirm": "Confirm password",
    "protect.owner": "Owner password (optional)",
    "redact.warning": "Redacted pages become images so the hidden text cannot be recovered.",
    "redact.fill": "Fill",
    "redact.fill.black": "Black",
    "redact.fill.white": "White",
    "redact.entirePage": "Redact entire page",
    "metadata.title": "Title",
    "metadata.author": "Author",
    "metadata.subject": "Subject",
    "settings.title": "Settings",
    "settings.language": "Language",
    "settings.language.system": "System",
    "settings.language.relaunch": "Changing language applies the next time Folio opens.",
    "settings.copyright": "Copyright © 2026 TGthms & Grok",
    "settings.repo": "GitHub",
    "menu.open": "Open…",
    "menu.export": "Export…",
    "menu.tools": "Tools",
    "menu.help": "Folio Help",
    "command.addFiles": "Add files…",
    "command.export": "Export…",
    "command.palette": "Search",
    "error.emptyWorkspace": "Add pages before exporting.",
    "error.unreadable": "Folio could not read that file.",
    "error.encrypted": "This PDF is locked.",
    "error.writeFailed": "Folio could not write the file.",
    "error.cancelled": "Export cancelled.",
    "error.diskFull": "The disk is full.",
    "error.passwordMismatch": "Passwords do not match.",
    "error.noPassword": "Enter a password.",
    "error.invalidRange": "That page range is not valid.",
    "error.outOfBounds": "That page number is out of range.",
    "suffix.merged": " – merged",
    "suffix.part": " – part",
    "suffix.compressed": " – compressed",
    "suffix.stamped": " – stamped",
    "suffix.locked": " – locked",
    "suffix.unlocked": " – unlocked",
    "suffix.searchable": " – searchable",
    "suffix.redacted": " – redacted",
    "suffix.page": " – page",
    "suffix.text": " – text",
    "page_count": "%d pages",
    "done": "Done",
    "cancel": "Cancel",
    "ok": "OK",
    "password.prompt": "This PDF is locked",
    "password.unlock": "Password",
    "pages.reverse": "Reverse order",
    "pages.duplicate": "Duplicate",
    "pages.insertBlank": "Insert blank page",
    "pages.removeBlank": "Remove blank pages",
    "inspector.encrypted": "Encrypted",
    "inspector.yes": "Yes",
    "inspector.no": "No",
    "menu.print": "Print…",
    "menu.go": "Go",
    "nav.next": "Next Page",
    "nav.previous": "Previous Page",
    "nav.first": "First Page",
    "nav.last": "Last Page",
    "nav.selectAll": "Select All Pages",
}

# Translations keyed by locale. Missing keys fall back only during authoring;
# the writer asserts completeness.
TR: dict[str, dict[str, str]] = {}


def add(locale: str, mapping: dict[str, str]) -> None:
    TR[locale] = mapping


add("es", {
    "app.name": "Folio", "group.organize": "Organizar", "group.reduce": "Reducir",
    "group.stamp": "Sello", "group.convert": "Convertir", "group.secure": "Seguridad",
    "recents": "Recientes", "recents.clear": "Borrar", "recents.empty": "No hay archivos recientes",
    "tool.pages": "Páginas", "tool.merge": "Combinar", "tool.split": "Dividir",
    "tool.compress": "Comprimir", "tool.watermark": "Marca de agua", "tool.pageNumbers": "Números de página",
    "tool.imagesToPDF": "Imágenes a PDF", "tool.pdfToImages": "PDF a imágenes",
    "tool.extractText": "Extraer texto", "tool.ocr": "OCR", "tool.protect": "Proteger",
    "tool.unlock": "Desbloquear", "tool.redact": "Tachar", "stage.pages": "Páginas", "stage.read": "Leer",
    "toolbar.rotate": "Girar a la derecha", "toolbar.rotateCCW": "Girar a la izquierda",
    "toolbar.delete": "Quitar del espacio de trabajo", "toolbar.addFiles": "Añadir archivos",
    "toolbar.inspector": "Inspector", "toolbar.settings": "Ajustes",
    "empty.headline": "Suelta un PDF",
    "empty.hint": "Los archivos se quedan en este Mac. Exportar no sustituye el original salvo que lo pidas.",
    "empty.drop": "Suelta PDF o imágenes, o haz clic para elegir",
    "export": "Exportar…", "export.saved": "Guardado", "export.replace": "Sustituir original",
    "export.replaceConfirm": "¿Sustituir el archivo original?",
    "export.replaceMessage": "Folio no puede deshacer esto.", "export.flatten": "Acoplar anotaciones",
    "inspector.pages": "Páginas", "inspector.size": "Tamaño", "inspector.document": "Documento",
    "compress.after": "Después", "compress.before": "Antes", "compress.preset": "Ajuste",
    "compress.small": "Pequeño (correo)", "compress.medium": "Medio", "compress.high": "Alta calidad",
    "compress.grayscale": "Escala de grises", "split.mode": "Dividir", "split.selected": "Páginas seleccionadas",
    "split.ranges": "Rangos", "split.rangesHint": "1-3, 7, 10-", "split.every": "Cada N páginas",
    "split.eachPage": "Cada página", "split.oneFilePerRange": "Un archivo por rango",
    "merge.help": "Ordena las páginas en la bandeja y exporta un solo archivo.",
    "watermark.text": "Texto de la marca", "watermark.position": "Posición",
    "watermark.position.center": "Centro", "watermark.position.tile": "Mosaico",
    "watermark.position.topLeft": "Arriba izquierda", "watermark.position.topRight": "Arriba derecha",
    "watermark.position.bottomLeft": "Abajo izquierda", "watermark.position.bottomRight": "Abajo derecha",
    "watermark.opacity": "Opacidad", "watermark.rotation": "Rotación",
    "pageNumbers.format": "Formato", "pageNumbers.format.number": "1", "pageNumbers.format.of": "1 / N",
    "pageNumbers.format.page": "Página 1", "pageNumbers.position": "Posición",
    "pageNumbers.position.headerLeft": "Encabezado izquierdo", "pageNumbers.position.headerCenter": "Encabezado centro",
    "pageNumbers.position.headerRight": "Encabezado derecho", "pageNumbers.position.footerLeft": "Pie izquierdo",
    "pageNumbers.position.footerCenter": "Pie centro", "pageNumbers.position.footerRight": "Pie derecho",
    "pageNumbers.startAt": "Empezar en", "pageNumbers.skipFirst": "Saltar la primera página",
    "images.pageSize": "Tamaño de página", "images.pageSize.imageSize": "Tamaño de la imagen",
    "images.pageSize.letter": "Carta", "images.pageSize.a4": "A4", "images.format": "Formato", "images.dpi": "PPP",
    "extract.help": "Exporta la capa de texto de estas páginas como un archivo .txt.",
    "ocr.help": "Reconoce el texto de páginas escaneadas y crea un PDF buscable. Solo en este Mac.",
    "unlock.help": "Escribe una copia desbloqueada. Folio necesita la contraseña con la que abriste el archivo.",
    "protect.password": "Contraseña", "protect.confirm": "Confirmar contraseña",
    "protect.owner": "Contraseña de propietario (opcional)",
    "redact.warning": "Las páginas tachadas se convierten en imágenes para que el texto no se pueda recuperar.",
    "redact.fill": "Relleno", "redact.fill.black": "Negro", "redact.fill.white": "Blanco",
    "redact.entirePage": "Tachar la página entera", "metadata.title": "Título", "metadata.author": "Autor",
    "metadata.subject": "Asunto", "settings.title": "Ajustes", "settings.language": "Idioma",
    "settings.language.system": "Sistema",
    "settings.language.relaunch": "El idioma se aplica la próxima vez que abras Folio.",
    "menu.open": "Abrir…", "menu.export": "Exportar…", "menu.tools": "Herramientas", "menu.help": "Ayuda de Folio",
    "command.addFiles": "Añadir archivos…", "command.export": "Exportar…", "command.palette": "Buscar",
    "error.emptyWorkspace": "Añade páginas antes de exportar.",
    "error.unreadable": "Folio no pudo leer ese archivo.", "error.encrypted": "Este PDF está bloqueado.",
    "error.writeFailed": "Folio no pudo escribir el archivo.", "error.cancelled": "Exportación cancelada.",
    "error.diskFull": "El disco está lleno.", "error.passwordMismatch": "Las contraseñas no coinciden.",
    "error.noPassword": "Introduce una contraseña.", "error.invalidRange": "Ese rango de páginas no es válido.",
    "error.outOfBounds": "Ese número de página está fuera de rango.",
    "suffix.merged": " – combinado", "suffix.part": " – parte", "suffix.compressed": " – comprimido",
    "suffix.stamped": " – sellado", "suffix.locked": " – bloqueado", "suffix.unlocked": " – desbloqueado",
    "suffix.searchable": " – buscable", "suffix.redacted": " – tachado", "suffix.page": " – página",
    "suffix.text": " – texto", "page_count": "%d páginas", "done": "Hecho", "cancel": "Cancelar", "ok": "OK",
    "password.prompt": "Este PDF está bloqueado", "password.unlock": "Contraseña",
    "pages.reverse": "Invertir orden", "pages.duplicate": "Duplicar",
    "pages.insertBlank": "Insertar página en blanco", "pages.removeBlank": "Quitar páginas en blanco",
})

# Remaining locales live in locales/*.json next to this script and are loaded below.

def write_catalog(table: dict[str, dict[str, str]]) -> None:
    strings = {}
    missing = []
    for key, english in EN.items():
        localizations = {}
        for locale in LOCALES:
            if locale == "en":
                value = english
            else:
                value = table.get(locale, {}).get(key)
                if value is None:
                    missing.append(f"{locale}:{key}")
                    value = english
            localizations[locale] = {"stringUnit": {"state": "translated", "value": value}}
        strings[key] = {"localizations": localizations}
    if missing:
        raise SystemExit(f"Missing {len(missing)} translations, e.g. {missing[:8]}")
    catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.1"}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n")
    print(f"Wrote {OUT} keys={len(EN)} locales={len(LOCALES)}")


PATCH = {
    "settings.copyright": {
        loc: "Copyright © 2026 TGthms & Grok"
        for loc in LOCALES
        if loc not in ("en", "Base")
    },
    "settings.repo": {
        loc: "GitHub"
        for loc in LOCALES
        if loc not in ("en", "Base")
    },
    "inspector.encrypted": {
        "es": "Cifrado", "fr": "Chiffré", "de": "Verschlüsselt", "it": "Crittografato",
        "pt-BR": "Criptografado", "pt-PT": "Encriptado", "nl": "Versleuteld", "da": "Krypteret",
        "sv": "Krypterad", "nb": "Kryptert", "fi": "Salattu", "pl": "Zaszyfrowany",
        "cs": "Šifrováno", "hu": "Titkosított", "ro": "Criptat", "el": "Κρυπτογραφημένο",
        "tr": "Şifreli", "ru": "Зашифрован", "uk": "Зашифровано", "ar": "مشفّر",
        "he": "מוצפן", "hi": "एन्क्रिप्टेड", "th": "เข้ารหัส", "vi": "Đã mã hóa",
        "id": "Terenkripsi", "ja": "暗号化", "ko": "암호화됨", "zh-Hans": "已加密", "zh-Hant": "已加密",
    },
    "inspector.yes": {
        "es": "Sí", "fr": "Oui", "de": "Ja", "it": "Sì", "pt-BR": "Sim", "pt-PT": "Sim",
        "nl": "Ja", "da": "Ja", "sv": "Ja", "nb": "Ja", "fi": "Kyllä", "pl": "Tak",
        "cs": "Ano", "hu": "Igen", "ro": "Da", "el": "Ναι", "tr": "Evet", "ru": "Да",
        "uk": "Так", "ar": "نعم", "he": "כן", "hi": "हाँ", "th": "ใช่", "vi": "Có",
        "id": "Ya", "ja": "はい", "ko": "예", "zh-Hans": "是", "zh-Hant": "是",
    },
    "inspector.no": {
        "es": "No", "fr": "Non", "de": "Nein", "it": "No", "pt-BR": "Não", "pt-PT": "Não",
        "nl": "Nee", "da": "Nej", "sv": "Nej", "nb": "Nei", "fi": "Ei", "pl": "Nie",
        "cs": "Ne", "hu": "Nem", "ro": "Nu", "el": "Όχι", "tr": "Hayır", "ru": "Нет",
        "uk": "Ні", "ar": "لا", "he": "לא", "hi": "नहीं", "th": "ไม่", "vi": "Không",
        "id": "Tidak", "ja": "いいえ", "ko": "아니요", "zh-Hans": "否", "zh-Hant": "否",
    },
    "menu.print": {
        "es": "Imprimir…", "fr": "Imprimer…", "de": "Drucken …", "it": "Stampa…",
        "pt-BR": "Imprimir…", "pt-PT": "Imprimir…", "nl": "Druk af…", "da": "Udskriv…",
        "sv": "Skriv ut…", "nb": "Skriv ut…", "fi": "Tulosta…", "pl": "Drukuj…",
        "cs": "Tisk…", "hu": "Nyomtatás…", "ro": "Tipărește…", "el": "Εκτύπωση…",
        "tr": "Yazdır…", "ru": "Печать…", "uk": "Друкувати…", "ar": "طباعة…",
        "he": "הדפס…", "hi": "प्रिंट…", "th": "พิมพ์…", "vi": "In…",
        "id": "Cetak…", "ja": "プリント…", "ko": "프린트…", "zh-Hans": "打印…", "zh-Hant": "列印…",
    },
    "menu.go": {
        "es": "Ir", "fr": "Aller", "de": "Gehe zu", "it": "Vai", "pt-BR": "Ir", "pt-PT": "Ir",
        "nl": "Ga", "da": "Gå", "sv": "Gå", "nb": "Gå", "fi": "Siirry", "pl": "Idź",
        "cs": "Přejít", "hu": "Ugrás", "ro": "Du-te", "el": "Μετάβαση", "tr": "Git", "ru": "Переход",
        "uk": "Перейти", "ar": "انتقال", "he": "מעבר", "hi": "जाएँ", "th": "ไป", "vi": "Đi tới",
        "id": "Buka", "ja": "移動", "ko": "이동", "zh-Hans": "转到", "zh-Hant": "前往",
    },
    "nav.next": {
        "es": "Página siguiente", "fr": "Page suivante", "de": "Nächste Seite", "it": "Pagina successiva",
        "pt-BR": "Próxima página", "pt-PT": "Página seguinte", "nl": "Volgende pagina", "da": "Næste side",
        "sv": "Nästa sida", "nb": "Neste side", "fi": "Seuraava sivu", "pl": "Następna strona",
        "cs": "Další stránka", "hu": "Következő oldal", "ro": "Pagina următoare", "el": "Επόμενη σελίδα",
        "tr": "Sonraki sayfa", "ru": "Следующая страница", "uk": "Наступна сторінка", "ar": "الصفحة التالية",
        "he": "העמוד הבא", "hi": "अगला पृष्ठ", "th": "หน้าถัดไป", "vi": "Trang sau",
        "id": "Halaman berikutnya", "ja": "次のページ", "ko": "다음 페이지", "zh-Hans": "下一页", "zh-Hant": "下一頁",
    },
    "nav.previous": {
        "es": "Página anterior", "fr": "Page précédente", "de": "Vorherige Seite", "it": "Pagina precedente",
        "pt-BR": "Página anterior", "pt-PT": "Página anterior", "nl": "Vorige pagina", "da": "Forrige side",
        "sv": "Föregående sida", "nb": "Forrige side", "fi": "Edellinen sivu", "pl": "Poprzednia strona",
        "cs": "Předchozí stránka", "hu": "Előző oldal", "ro": "Pagina anterioară", "el": "Προηγούμενη σελίδα",
        "tr": "Önceki sayfa", "ru": "Предыдущая страница", "uk": "Попередня сторінка", "ar": "الصفحة السابقة",
        "he": "העמוד הקודם", "hi": "पिछला पृष्ठ", "th": "หน้าก่อน", "vi": "Trang trước",
        "id": "Halaman sebelumnya", "ja": "前のページ", "ko": "이전 페이지", "zh-Hans": "上一页", "zh-Hant": "上一頁",
    },
    "nav.first": {
        "es": "Primera página", "fr": "Première page", "de": "Erste Seite", "it": "Prima pagina",
        "pt-BR": "Primeira página", "pt-PT": "Primeira página", "nl": "Eerste pagina", "da": "Første side",
        "sv": "Första sidan", "nb": "Første side", "fi": "Ensimmäinen sivu", "pl": "Pierwsza strona",
        "cs": "První stránka", "hu": "Első oldal", "ro": "Prima pagină", "el": "Πρώτη σελίδα",
        "tr": "İlk sayfa", "ru": "Первая страница", "uk": "Перша сторінка", "ar": "الصفحة الأولى",
        "he": "העמוד הראשון", "hi": "पहला पृष्ठ", "th": "หน้าแรก", "vi": "Trang đầu",
        "id": "Halaman pertama", "ja": "最初のページ", "ko": "첫 페이지", "zh-Hans": "第一页", "zh-Hant": "第一頁",
    },
    "nav.last": {
        "es": "Última página", "fr": "Dernière page", "de": "Letzte Seite", "it": "Ultima pagina",
        "pt-BR": "Última página", "pt-PT": "Última página", "nl": "Laatste pagina", "da": "Sidste side",
        "sv": "Sista sidan", "nb": "Siste side", "fi": "Viimeinen sivu", "pl": "Ostatnia strona",
        "cs": "Poslední stránka", "hu": "Utolsó oldal", "ro": "Ultima pagină", "el": "Τελευταία σελίδα",
        "tr": "Son sayfa", "ru": "Последняя страница", "uk": "Остання сторінка", "ar": "الصفحة الأخيرة",
        "he": "העמוד האחרון", "hi": "अंतिम पृष्ठ", "th": "หน้าสุดท้าย", "vi": "Trang cuối",
        "id": "Halaman terakhir", "ja": "最後のページ", "ko": "마지막 페이지", "zh-Hans": "最后一页", "zh-Hant": "最後一頁",
    },
    "nav.selectAll": {
        "es": "Seleccionar todas las páginas", "fr": "Sélectionner toutes les pages", "de": "Alle Seiten auswählen",
        "it": "Seleziona tutte le pagine", "pt-BR": "Selecionar todas as páginas", "pt-PT": "Selecionar todas as páginas",
        "nl": "Alle pagina’s selecteren", "da": "Vælg alle sider", "sv": "Markera alla sidor", "nb": "Velg alle sider",
        "fi": "Valitse kaikki sivut", "pl": "Zaznacz wszystkie strony", "cs": "Vybrat všechny stránky",
        "hu": "Összes oldal kijelölése", "ro": "Selectează toate paginile", "el": "Επιλογή όλων των σελίδων",
        "tr": "Tüm sayfaları seç", "ru": "Выбрать все страницы", "uk": "Вибрати всі сторінки",
        "ar": "تحديد كل الصفحات", "he": "בחר את כל העמודים", "hi": "सभी पृष्ठ चुनें", "th": "เลือกทุกหน้า",
        "vi": "Chọn mọi trang", "id": "Pilih semua halaman", "ja": "すべてのページを選択",
        "ko": "모든 페이지 선택", "zh-Hans": "选择所有页面", "zh-Hant": "選取所有頁面",
    },
}

if __name__ == "__main__":
    extra = Path(__file__).with_name("locales.json")
    if extra.exists():
        loaded = json.loads(extra.read_text())
        for loc, mapping in loaded.items():
            TR.setdefault(loc, {}).update(mapping)
    for key, per_locale in PATCH.items():
        for loc, value in per_locale.items():
            TR.setdefault(loc, {})[key] = value
    write_catalog(TR)

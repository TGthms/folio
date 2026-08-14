import AppKit
import PDFKit

enum CompressService {
    static func shouldRasterize(_ page: PDFPage, preset: CompressPreset) -> Bool {
        if preset == .high { return false }
        let text = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty || hasLargeImageHint(page)
    }

    static func rasterize(
        _ page: PDFPage,
        dpi: CGFloat,
        quality: CGFloat,
        grayscale: Bool
    ) -> PDFPage {
        let bounds = page.bounds(for: .mediaBox)
        let scale = max(dpi / 72.0, 0.25)
        let pixelSize = CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
        let image = NSImage(size: pixelSize)
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.saveGState()
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
            page.draw(with: .mediaBox, to: ctx)
            ctx.restoreGState()
        }
        image.unlockFocus()

        guard let jpeg = PDFPageGraphics.jpegData(from: image, quality: quality, grayscale: grayscale),
              let compressed = NSImage(data: jpeg)
        else {
            return page
        }
        return PDFPageGraphics.pageFromImage(compressed, canvas: bounds.size)
    }

    static func applyGrayscale(_ page: PDFPage) -> PDFPage {
        rasterize(page, dpi: 144, quality: 0.85, grayscale: true)
    }

    private static func hasLargeImageHint(_ page: PDFPage) -> Bool {
        guard let data = page.dataRepresentation, data.count > 180_000 else { return false }
        return true
    }
}

import AppKit
import PDFKit

enum RedactService {
    static func burn(_ page: PDFPage, redactions: [Redaction], fill: RedactFill) -> PDFPage {
        guard !redactions.isEmpty else { return page }
        let scratch = PDFDocument()
        scratch.insert(page, at: 0)
        guard let owned = scratch.page(at: 0) else { return page }
        return burnOwned(owned, redactions: redactions, fill: fill)
    }

    private static func burnOwned(_ page: PDFPage, redactions: [Redaction], fill: RedactFill) -> PDFPage {
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2
        let pixelSize = CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
        let image = NSImage(size: pixelSize)
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.saveGState()
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
            page.draw(with: .mediaBox, to: ctx)
            ctx.setFillColor((fill == .white ? NSColor.white : NSColor.black).cgColor)
            for redaction in redactions {
                ctx.fill(redaction.rect.intersection(bounds.insetBy(dx: -1, dy: -1)))
            }
            ctx.restoreGState()
        }
        image.unlockFocus()
        return PDFPageGraphics.pageFromImage(image, canvas: bounds.size)
    }

    static func clipped(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        rect.intersection(bounds)
    }
}

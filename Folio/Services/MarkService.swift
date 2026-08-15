import AppKit
import PDFKit

enum MarkService {
    static func burn(_ page: PDFPage, marks: [PageMark], crop: CGRect?) -> PDFPage {
        guard !marks.isEmpty || crop != nil else { return page }
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2
        let pixelSize = CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
        let image = NSImage(size: pixelSize)
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.saveGState()
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
            if let crop {
                ctx.clip(to: crop.intersection(bounds))
            }
            page.draw(with: .mediaBox, to: ctx)
            for mark in marks {
                draw(mark, in: ctx, bounds: bounds)
            }
            ctx.restoreGState()
        }
        image.unlockFocus()
        let canvas = crop?.intersection(bounds).size ?? bounds.size
        let drawn = PDFPageGraphics.pageFromImage(image, canvas: canvas)
        return drawn
    }

    private static func draw(_ mark: PageMark, in ctx: CGContext, bounds: CGRect) {
        let rect = mark.rect.intersection(bounds.insetBy(dx: -1, dy: -1))
        switch mark.kind {
        case .highlight:
            ctx.setFillColor(NSColor.systemYellow.withAlphaComponent(0.35).cgColor)
            ctx.fill(rect)
        case .underline:
            ctx.setStrokeColor(NSColor.systemYellow.cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 1))
            ctx.strokePath()
        case .textBox:
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.92).cgColor)
            ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.35).cgColor)
            ctx.setLineWidth(0.6)
            ctx.fill(rect)
            ctx.stroke(rect)
            let text = mark.text as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: max(8, min(14, rect.height * 0.45))),
                .foregroundColor: NSColor.black,
            ]
            text.draw(in: rect.insetBy(dx: 4, dy: 3), withAttributes: attrs)
        case .stroke:
            ctx.setStrokeColor(NSColor.systemRed.cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            let points = mark.points
            guard let first = points.first else { return }
            ctx.beginPath()
            ctx.move(to: first)
            for point in points.dropFirst() {
                ctx.addLine(to: point)
            }
            ctx.strokePath()
        }
    }
}

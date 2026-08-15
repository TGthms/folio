import AppKit
import PDFKit

enum MarkService {
    static func apply(_ page: PDFPage, marks: [PageMark], crop: CGRect?, flatten: Bool) -> PDFPage {
        if flatten {
            return burn(page, marks: marks, crop: crop)
        }
        let media = page.bounds(for: .mediaBox)
        var result = page
        var live = marks
        if let crop {
            let clip = crop.intersection(media)
            result = PDFPageGraphics.crop(result, to: clip)
            live = shifted(marks, by: CGPoint(x: -clip.minX, y: -clip.minY))
        }
        AnnotationService.sync(page: result, marks: live, crop: nil)
        return result
    }

    static func burn(_ page: PDFPage, marks: [PageMark], crop: CGRect?) -> PDFPage {
        guard !marks.isEmpty || crop != nil else { return page }
        let media = page.bounds(for: .mediaBox)
        var result = page
        if !marks.isEmpty {
            result = PDFPageGraphics.redraw(result) { ctx, _ in
                for mark in marks {
                    draw(mark, in: ctx, bounds: media)
                }
            }
        }
        if let crop {
            result = PDFPageGraphics.crop(result, to: crop.intersection(media))
        }
        return result
    }

    static func shifted(_ marks: [PageMark], by delta: CGPoint) -> [PageMark] {
        marks.map { mark in
            var next = mark
            next.rect = next.rect.offsetBy(dx: delta.x, dy: delta.y)
            if !next.points.isEmpty {
                next.points = next.points.map { CGPoint(x: $0.x + delta.x, y: $0.y + delta.y) }
            }
            return next
        }
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

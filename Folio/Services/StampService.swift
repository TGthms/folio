import AppKit
import CoreText
import PDFKit

enum StampService {
    static func applyWatermark(_ page: PDFPage, options: WatermarkOptions) -> PDFPage {
        PDFPageGraphics.redraw(page) { ctx, bounds in
            ctx.saveGState()
            ctx.setAlpha(CGFloat(max(0, min(1, options.opacity))))
            switch options.position {
            case .tile:
                drawTiled(ctx: ctx, bounds: bounds, options: options)
            default:
                drawOnce(ctx: ctx, bounds: bounds, options: options, at: point(for: options.position, in: bounds))
            }
            ctx.restoreGState()
        }
    }

    static func applyPageNumber(_ page: PDFPage, display: String, options: PageNumberOptions) -> PDFPage {
        PDFPageGraphics.redraw(page) { ctx, bounds in
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor(red: 0.11, green: 0.10, blue: 0.08, alpha: 0.72),
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: display, attributes: attrs))
            let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            let point = numberPoint(options.position, in: bounds, textWidth: width)
            ctx.textPosition = point
            CTLineDraw(line, ctx)
        }
    }

    static func displayNumber(index: Int, total: Int, options: PageNumberOptions) -> String {
        let value = options.startAt + index
        switch options.format {
        case .number:
            return "\(value)"
        case .of:
            return "\(value) / \(total)"
        case .page:
            return "Page \(value)"
        }
    }

    private static func point(for position: WatermarkPosition, in bounds: CGRect) -> CGPoint {
        switch position {
        case .center, .tile: return CGPoint(x: bounds.midX, y: bounds.midY)
        case .topLeft: return CGPoint(x: bounds.minX + 72, y: bounds.maxY - 72)
        case .topRight: return CGPoint(x: bounds.maxX - 72, y: bounds.maxY - 72)
        case .bottomLeft: return CGPoint(x: bounds.minX + 72, y: bounds.minY + 72)
        case .bottomRight: return CGPoint(x: bounds.maxX - 72, y: bounds.minY + 72)
        }
    }

    private static func numberPoint(_ position: PageNumberPosition, in bounds: CGRect, textWidth: CGFloat) -> CGPoint {
        let margin: CGFloat = 28
        switch position {
        case .headerLeft: return CGPoint(x: bounds.minX + margin, y: bounds.maxY - 28)
        case .headerCenter: return CGPoint(x: bounds.midX - textWidth / 2, y: bounds.maxY - 28)
        case .headerRight: return CGPoint(x: bounds.maxX - margin - textWidth, y: bounds.maxY - 28)
        case .footerLeft: return CGPoint(x: bounds.minX + margin, y: bounds.minY + 22)
        case .footerCenter: return CGPoint(x: bounds.midX - textWidth / 2, y: bounds.minY + 22)
        case .footerRight: return CGPoint(x: bounds.maxX - margin - textWidth, y: bounds.minY + 22)
        }
    }

    private static func drawOnce(ctx: CGContext, bounds: CGRect, options: WatermarkOptions, at center: CGPoint) {
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: CGFloat(options.rotation) * .pi / 180)
        if let url = options.imageURL, let image = NSImage(contentsOf: url),
           let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let size = CGSize(width: min(240, image.size.width), height: min(240, image.size.height))
            ctx.draw(cg, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        } else {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 42, weight: .semibold),
                .foregroundColor: NSColor(red: 0.76, green: 0.23, blue: 0.13, alpha: 1),
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: options.text, attributes: attrs))
            let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            ctx.textPosition = CGPoint(x: -width / 2, y: -12)
            CTLineDraw(line, ctx)
        }
        ctx.restoreGState()
    }

    private static func drawTiled(ctx: CGContext, bounds: CGRect, options: WatermarkOptions) {
        let stepX: CGFloat = 220
        let stepY: CGFloat = 160
        var y = bounds.minY + 40
        while y < bounds.maxY {
            var x = bounds.minX + 40
            while x < bounds.maxX {
                drawOnce(ctx: ctx, bounds: bounds, options: options, at: CGPoint(x: x, y: y))
                x += stepX
            }
            y += stepY
        }
    }
}

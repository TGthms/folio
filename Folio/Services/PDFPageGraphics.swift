import AppKit
import CoreGraphics
import CoreText
import PDFKit

enum PDFPageGraphics {
    static let letter = CGSize(width: 612, height: 792)

    static func makePage(text: String, size: CGSize = letter, background: NSColor = .white) -> PDFPage {
        let data = makePDFData(size: size) { ctx, bounds in
            ctx.setFillColor(background.cgColor)
            ctx.fill(bounds)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 24),
                .foregroundColor: NSColor.black,
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
            ctx.textPosition = CGPoint(x: 72, y: bounds.height - 100)
            CTLineDraw(line, ctx)
        }
        guard let document = PDFDocument(data: data), let page = document.page(at: 0) else {
            return PDFPage()
        }
        return page
    }

    static func makeBlankPage(size: CGSize = letter) -> PDFPage {
        let data = makePDFData(size: size) { ctx, bounds in
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(bounds)
        }
        guard let document = PDFDocument(data: data), let page = document.page(at: 0) else {
            return PDFPage()
        }
        return page
    }

    static func makeDocument(pageCount: Int, label: String = "P") -> PDFDocument {
        let document = PDFDocument()
        for index in 0..<pageCount {
            document.insert(makePage(text: "\(label)\(index + 1)"), at: index)
        }
        return document
    }

    static func makePDFData(size: CGSize, draw: (CGContext, CGRect) -> Void) -> Data {
        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: size)
        guard let consumer = CGDataConsumer(data: data),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else {
            return Data()
        }
        context.beginPDFPage(nil)
        draw(context, mediaBox)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }

    static func redraw(_ page: PDFPage, overlay: ((CGContext, CGRect) -> Void)? = nil) -> PDFPage {
        let bounds = page.bounds(for: .mediaBox)
        let data = makePDFData(size: bounds.size) { ctx, box in
            ctx.saveGState()
            ctx.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
            page.draw(with: .mediaBox, to: ctx)
            ctx.restoreGState()
            overlay?(ctx, box)
        }
        return PDFDocument(data: data)?.page(at: 0) ?? page
    }

    /// New page whose media box is `rect.size`, drawn 1:1 from `rect` in the source. No import inset.
    static func crop(_ page: PDFPage, to rect: CGRect) -> PDFPage {
        let media = page.bounds(for: .mediaBox)
        let clip = rect.intersection(media)
        guard !clip.isNull, clip.width > 1, clip.height > 1 else { return page }
        if clip.equalTo(media) { return page }
        let data = makePDFData(size: clip.size) { ctx, _ in
            ctx.saveGState()
            ctx.translateBy(x: -clip.origin.x, y: -clip.origin.y)
            page.draw(with: .mediaBox, to: ctx)
            ctx.restoreGState()
        }
        return PDFDocument(data: data)?.page(at: 0) ?? page
    }

    static func pageFromImage(_ image: NSImage, canvas: CGSize?) -> PDFPage {
        let imageSize = image.size
        let pageSize = canvas ?? imageSize
        let data = makePDFData(size: pageSize) { ctx, bounds in
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(bounds)
            let fitted = aspectFit(imageSize, in: bounds.insetBy(dx: 18, dy: 18))
            if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                ctx.draw(cg, in: fitted)
            }
        }
        return PDFDocument(data: data)?.page(at: 0) ?? PDFPage(image: image) ?? PDFPage()
    }

    static func aspectFit(_ size: CGSize, in rect: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return rect }
        let scale = min(rect.width / size.width, rect.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: rect.midX - fitted.width / 2,
            y: rect.midY - fitted.height / 2,
            width: fitted.width,
            height: fitted.height
        )
    }

    static func jpegData(from image: NSImage, quality: CGFloat, grayscale: Bool) -> Data? {
        guard var cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        if grayscale, let filtered = grayscaleImage(cg) {
            cg = filtered
        }
        let bitmap = NSBitmapImageRep(cgImage: cg)
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }

    static func grayscaleImage(_ image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
}

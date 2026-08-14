import AppKit
import PDFKit

enum ImageConvertService {
    static func imageURLs(from urls: [URL]) -> [URL] {
        urls.filter { isImage($0) }
    }

    static func isImage(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "tif", "tiff", "heic", "heif", "webp", "gif", "bmp"].contains(ext)
    }

    static func isPDF(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "pdf"
    }

    static func render(_ page: PDFPage, dpi: CGFloat, format: ImageExportFormat) -> Data? {
        let bounds = page.bounds(for: .mediaBox)
        let scale = max(dpi / 72, 0.25)
        let size = CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
        let image = NSImage(size: size)
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
            page.draw(with: .mediaBox, to: ctx)
        }
        image.unlockFocus()
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cg)
        switch format {
        case .png:
            return rep.representation(using: .png, properties: [:])
        case .jpeg:
            return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.86])
        }
    }

    static func extractEmbeddedImages(from page: PDFPage) -> [Data] {
        guard let pageData = page.dataRepresentation,
              let provider = CGDataProvider(data: pageData as CFData),
              let document = CGPDFDocument(provider),
              let cgPage = document.page(at: 1),
              let resources = cgPage.dictionary
        else {
            return []
        }
        var xObject: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(resources, "XObject", &xObject), let xObject else {
            return []
        }
        var found: [Data] = []
        CGPDFDictionaryApplyBlock(xObject, { _, object, _ in
            var stream: CGPDFStreamRef?
            guard CGPDFObjectGetValue(object, .stream, &stream), let stream else { return true }
            guard let info = CGPDFStreamGetDictionary(stream) else { return true }
            var name: UnsafePointer<CChar>?
            if CGPDFDictionaryGetName(info, "Subtype", &name), let name, String(cString: name) == "Image" {
                var format = CGPDFDataFormat.raw
                if let data = CGPDFStreamCopyData(stream, &format) {
                    found.append(data as Data)
                }
            }
            return true
        }, nil)
        return found
    }
}

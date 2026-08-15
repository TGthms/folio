import AppKit
import PDFKit

@MainActor
final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, NSImage>()

    init() {
        cache.countLimit = 256
    }

    func key(for page: PageRef, width: Int) -> NSString {
        "\(page.id.uuidString)-\(page.rotation)-\(page.redactions.count)-\(page.marks.count)-\(page.cropRect?.debugDescription ?? "-")-\(width)" as NSString
    }

    func image(for page: PageRef, size: CGSize) -> NSImage? {
        cache.object(forKey: key(for: page, width: Int(size.width)))
    }

    func store(_ image: NSImage, for page: PageRef, size: CGSize) {
        cache.setObject(image, forKey: key(for: page, width: Int(size.width)))
    }

    func generate(for page: PageRef, size: CGSize) -> NSImage? {
        if let hit = image(for: page, size: size) { return hit }
        guard let original = try? PDFIO.page(for: page),
              let detached = try? PDFPageIsolation.detached(original)
        else { return nil }
        detached.rotation = (detached.rotation + page.rotation) % 360
        let rendered: PDFPage
        if page.hasEdits {
            rendered = MarkService.burn(detached, marks: page.marks, crop: page.cropRect)
        } else {
            rendered = detached
        }
        let thumb = rendered.thumbnail(of: size, for: .mediaBox)
        store(thumb, for: page, size: size)
        return thumb
    }

    func invalidate() {
        cache.removeAllObjects()
    }
}

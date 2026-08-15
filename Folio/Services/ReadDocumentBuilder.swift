import PDFKit

/// Assembles the Read-mode document from the full workspace page list.
enum ReadDocumentBuilder {
    /// Identity for the assembled Read document. Marks and crop stay as live overlays.
    static func token(pages: [PageRef]) -> String {
        if pages.isEmpty { return "empty" }
        return pages.map { page in
            "\(page.id.uuidString):\(page.rotation):\(page.redactions.count):\(sourceToken(page.source))"
        }.joined(separator: "|")
    }

    static func sourceToken(_ source: PageSource) -> String {
        switch source {
        case .pdf(let url, let index):
            return "p:\(url.path):\(index)"
        case .image(let url):
            return "i:\(url.path)"
        case .blank(let size):
            return "b:\(Int(size.width))x\(Int(size.height))"
        }
    }

    @MainActor
    static func build(pages: [PageRef]) throws -> PDFDocument {
        guard !pages.isEmpty else { throw FolioError.emptyWorkspace }
        let document = PDFDocument()
        for (index, ref) in pages.enumerated() {
            let original = try PDFIO.page(for: ref)
            var page = try PDFPageIsolation.detached(original)
            page.rotation = (page.rotation + ref.rotation) % 360
            if !ref.redactions.isEmpty {
                page = RedactService.burn(page, redactions: ref.redactions, fill: .black)
            }
            AnnotationService.sync(page: page, marks: ref.marks, crop: ref.cropRect)
            document.insert(page, at: index)
        }
        return document
    }
}

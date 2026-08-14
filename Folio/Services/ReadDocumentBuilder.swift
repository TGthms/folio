import PDFKit

/// Assembles the Read-mode document from the full workspace page list.
enum ReadDocumentBuilder {
    /// Stable identity for the assembled document (order, rotation, redactions).
    static func token(pages: [PageRef]) -> String {
        if pages.isEmpty { return "empty" }
        return pages.map { "\($0.id.uuidString):\($0.rotation):\($0.redactions.count)" }.joined(separator: "|")
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
            document.insert(page, at: index)
        }
        return document
    }
}

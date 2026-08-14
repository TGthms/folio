import PDFKit

enum PDFPageIsolation {
    /// Returns a page that does not alias the PDFIO-cached original.
    /// `PDFDocument.insert` shares the same `PDFPage` instance.
    static func detached(_ original: PDFPage) throws -> PDFPage {
        if let copy = original.copy() as? PDFPage {
            return copy
        }
        guard let data = original.dataRepresentation,
              let document = PDFDocument(data: data),
              let page = document.page(at: 0)
        else {
            throw FolioError.writeFailed
        }
        return page
    }
}

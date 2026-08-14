import PDFKit
import XCTest
@testable import Folio

@MainActor
final class PDFBuilderTests: XCTestCase {
    func testMergeTwoDocuments() async throws {
        let urlA = try writeFixture(name: "A", pages: 1)
        let urlB = try writeFixture(name: "B", pages: 1)
        let pages = [
            PageRef(source: .pdf(url: urlA, pageIndex: 0)),
            PageRef(source: .pdf(url: urlB, pageIndex: 0)),
        ]
        let document = try await PDFBuilder.build(pages: pages, tool: .merge, options: ExportOptions())
        XCTAssertEqual(document.pageCount, 2)
        XCTAssertTrue(TextService.pageHasText(document.page(at: 0)!))
        XCTAssertTrue(TextService.extract(from: [document.page(at: 0)!]).contains("A1"))
        XCTAssertTrue(TextService.extract(from: [document.page(at: 1)!]).contains("B1"))
    }

    func testRotationApplied() async throws {
        let url = try writeFixture(name: "R", pages: 1)
        var page = PageRef(source: .pdf(url: url, pageIndex: 0))
        page.rotate(by: 90)
        let document = try await PDFBuilder.build(pages: [page], tool: .pages, options: ExportOptions())
        XCTAssertEqual(document.page(at: 0)?.rotation, 90)
    }

    func testBlankInsert() async throws {
        let page = PageRef(source: .blank(size: CGSize(width: 400, height: 500)))
        let document = try await PDFBuilder.build(pages: [page], tool: .pages, options: ExportOptions())
        XCTAssertEqual(document.pageCount, 1)
        let bounds = document.page(at: 0)!.bounds(for: .mediaBox)
        XCTAssertEqual(bounds.width, 400, accuracy: 0.5)
        XCTAssertEqual(bounds.height, 500, accuracy: 0.5)
    }

    func testImageSourceBecomesPage() async throws {
        let url = try writePNG()
        let page = PageRef(source: .image(url: url))
        var options = ExportOptions()
        options.imagePageSize = .letter
        let document = try await PDFBuilder.build(pages: [page], tool: .imagesToPDF, options: options)
        XCTAssertEqual(document.pageCount, 1)
        let bounds = document.page(at: 0)!.bounds(for: .mediaBox)
        XCTAssertEqual(bounds.width, 612, accuracy: 1)
    }

    func testRedactionBurnsPage() async throws {
        let url = try writeFixture(name: "SECRETWORD", pages: 1)
        var page = PageRef(source: .pdf(url: url, pageIndex: 0))
        page.redactions = [Redaction(rect: CGRect(x: 0, y: 0, width: 2000, height: 2000))]
        let document = try await PDFBuilder.build(pages: [page], tool: .redact, options: ExportOptions())
        let text = TextService.extract(from: [document.page(at: 0)!])
        XCTAssertFalse(text.contains("SECRETWORD"))
    }

    func testGraphicsFactoryPageCount() {
        let document = PDFPageGraphics.makeDocument(pageCount: 4, label: "Q")
        XCTAssertEqual(document.pageCount, 4)
        XCTAssertTrue((document.page(at: 2)?.string ?? "").contains("Q3"))
    }

    private func writeFixture(name: String, pages: Int) throws -> URL {
        let document = PDFPageGraphics.makeDocument(pageCount: pages, label: name)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("folio-\(name)-\(UUID().uuidString).pdf")
        guard document.write(to: url) else { throw FolioError.writeFailed }
        return url
    }

    private func writePNG() throws -> URL {
        let image = NSImage(size: NSSize(width: 40, height: 20))
        image.lockFocus()
        NSColor.red.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 40, height: 20)).fill()
        image.unlockFocus()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("folio-img-\(UUID().uuidString).png")
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:])
        else { throw FolioError.writeFailed }
        try data.write(to: url)
        return url
    }
}

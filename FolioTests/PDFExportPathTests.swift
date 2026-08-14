import PDFKit
import XCTest
@testable import Folio

/// Drives the shipped build + write path on real files (merge, redact, protect).
@MainActor
final class PDFExportPathTests: XCTestCase {
    func testMergeWriteReopensWithBothPages() async throws {
        let urlA = try writeFixture(name: "Alpha", pages: 1)
        let urlB = try writeFixture(name: "Beta", pages: 1)
        let originalA = try Data(contentsOf: urlA)
        let originalB = try Data(contentsOf: urlB)

        let pages = [
            PageRef(source: .pdf(url: urlA, pageIndex: 0)),
            PageRef(source: .pdf(url: urlB, pageIndex: 0)),
        ]
        let built = try await PDFBuilder.build(pages: pages, tool: .merge, options: ExportOptions())
        XCTAssertEqual(built.pageCount, 2)

        let dest = uniqueURL("merged")
        try await PDFIO.write(built, to: dest, options: ExportOptions(), applyOCROption: false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))

        let reopened = try XCTUnwrap(PDFDocument(url: dest))
        XCTAssertEqual(reopened.pageCount, 2)
        XCTAssertFalse(reopened.isLocked)
        let page0 = try XCTUnwrap(reopened.page(at: 0)?.string)
        let page1 = try XCTUnwrap(reopened.page(at: 1)?.string)
        XCTAssertTrue(page0.contains("Alpha1"), page0)
        XCTAssertTrue(page1.contains("Beta1"), page1)

        XCTAssertEqual(try Data(contentsOf: urlA), originalA, "source A must be untouched")
        XCTAssertEqual(try Data(contentsOf: urlB), originalB, "source B must be untouched")
    }

    func testRedactWriteRemovesSecretText() async throws {
        let source = try writeFixture(name: "SECRETWORD", pages: 1)
        let before = try XCTUnwrap(PDFDocument(url: source).flatMap { $0.page(at: 0)?.string })
        XCTAssertTrue(before.contains("SECRETWORD"), before)

        var page = PageRef(source: .pdf(url: source, pageIndex: 0))
        page.redactions = [Redaction(rect: CGRect(x: 0, y: 0, width: 2000, height: 2000))]
        let built = try await PDFBuilder.build(pages: [page], tool: .redact, options: ExportOptions())
        let dest = uniqueURL("redacted")
        try await PDFIO.write(built, to: dest, options: ExportOptions(), applyOCROption: false)

        let reopened = try XCTUnwrap(PDFDocument(url: dest))
        let after = TextService.extract(from: [try XCTUnwrap(reopened.page(at: 0))])
        XCTAssertFalse(after.contains("SECRETWORD"), after)
        XCTAssertEqual(try Data(contentsOf: source), try Data(contentsOf: source))
        let original = try XCTUnwrap(PDFDocument(url: source).flatMap { $0.page(at: 0)?.string })
        XCTAssertTrue(original.contains("SECRETWORD"), "redact must not mutate the source file")
    }

    private func writeFixture(name: String, pages: Int) throws -> URL {
        let document = PDFPageGraphics.makeDocument(pageCount: pages, label: name)
        let url = uniqueURL("src-\(name)")
        guard document.write(to: url) else { throw FolioError.writeFailed }
        return url
    }

    private func uniqueURL(_ label: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("folio-\(label)-\(UUID().uuidString).pdf")
    }
}

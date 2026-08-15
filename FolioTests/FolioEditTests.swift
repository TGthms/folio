import PDFKit
import XCTest
@testable import Folio

@MainActor
final class FolioEditTests: XCTestCase {
    func testReadTokenIgnoresMarksSoOverlayStaysLive() {
        var page = PageRef(source: .blank(size: CGSize(width: 200, height: 200)))
        let before = ReadDocumentBuilder.token(pages: [page])
        page.marks = [PageMark(kind: .highlight, rect: CGRect(x: 10, y: 10, width: 40, height: 12))]
        page.cropRect = CGRect(x: 4, y: 4, width: 180, height: 180)
        XCTAssertEqual(ReadDocumentBuilder.token(pages: [page]), before)
    }

    func testReadTokenChangesWhenSourceIsReplaced() {
        let first = PageRef(source: .blank(size: CGSize(width: 200, height: 200)))
        var replaced = first
        replaced.source = .blank(size: CGSize(width: 400, height: 400))
        XCTAssertNotEqual(
            ReadDocumentBuilder.token(pages: [first]),
            ReadDocumentBuilder.token(pages: [replaced])
        )
    }

    func testDuplicateCopiesMarksAndCrop() {
        var state = WorkspaceState()
        var page = PageRef(source: .blank(size: CGSize(width: 200, height: 200)))
        page.marks = [PageMark(kind: .textBox, rect: CGRect(x: 8, y: 8, width: 80, height: 24), text: "Hi")]
        page.cropRect = CGRect(x: 10, y: 10, width: 100, height: 100)
        state.append([page])
        state.selectedIDs = [page.id]
        state.duplicateSelected()
        XCTAssertEqual(state.pages.count, 2)
        XCTAssertEqual(state.pages[1].marks.count, 1)
        XCTAssertEqual(state.pages[1].marks[0].text, "Hi")
        XCTAssertEqual(state.pages[1].cropRect, page.cropRect)
        XCTAssertNotEqual(state.pages[1].id, page.id)
    }

    func testMarkBurnChangesPageAndLeavesSourceUntouched() async throws {
        let url = try writeFixture(name: "MARKSRC", pages: 1)
        let sourceBytes = try Data(contentsOf: url)
        var page = PageRef(source: .pdf(url: url, pageIndex: 0))
        page.marks = [
            PageMark(kind: .highlight, rect: CGRect(x: 40, y: 600, width: 240, height: 36)),
            PageMark(kind: .textBox, rect: CGRect(x: 72, y: 520, width: 180, height: 28), text: "FolioEdit"),
        ]
        let marked = try await PDFBuilder.build(pages: [page], tool: .edit, options: ExportOptions())
        let plain = try await PDFBuilder.build(
            pages: [PageRef(source: .pdf(url: url, pageIndex: 0))],
            tool: .pages,
            options: ExportOptions()
        )
        XCTAssertEqual(try Data(contentsOf: url), sourceBytes)
        XCTAssertNotEqual(marked.dataRepresentation(), plain.dataRepresentation())
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("folio-edit-\(UUID().uuidString).pdf")
        XCTAssertTrue(marked.write(to: dest))
        XCTAssertEqual(try Data(contentsOf: url), sourceBytes)
    }

    func testCropBurnShrinksPage() async throws {
        let url = try writeFixture(name: "CROP", pages: 1)
        var page = PageRef(source: .pdf(url: url, pageIndex: 0))
        page.cropRect = CGRect(x: 100, y: 100, width: 220, height: 280)
        let document = try await PDFBuilder.build(pages: [page], tool: .edit, options: ExportOptions())
        let bounds = try XCTUnwrap(document.page(at: 0)).bounds(for: .mediaBox)
        XCTAssertEqual(bounds.width, 220, accuracy: 2)
        XCTAssertEqual(bounds.height, 280, accuracy: 2)
    }

    func testSaveDoesNotWriteUntilDestinationIsChosen() async throws {
        let model = AppModel()
        let url = try writeFixture(name: "SAVE", pages: 1)
        let before = try Data(contentsOf: url)
        await model.importURLsAsync([url])
        model.addMark(
            PageMark(kind: .highlight, rect: CGRect(x: 10, y: 10, width: 20, height: 20)),
            to: model.workspace.pages[0].id
        )
        XCTAssertTrue(model.hasUnsavedEdits)
        XCTAssertEqual(try Data(contentsOf: url), before)
    }

    private func writeFixture(name: String, pages: Int) throws -> URL {
        let document = PDFPageGraphics.makeDocument(pageCount: pages, label: name)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("folio-edit-\(name)-\(UUID().uuidString).pdf")
        guard document.write(to: url) else { throw FolioError.writeFailed }
        return url
    }
}

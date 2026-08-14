import PDFKit
import XCTest
@testable import Folio

@MainActor
final class ReadAndNavTests: XCTestCase {
    func testReadDocumentIncludesEveryWorkspacePageInOrder() async throws {
        let urlA = try writeFixture(name: "A", pages: 1)
        let urlB = try writeFixture(name: "B", pages: 1)
        let urlC = try writeFixture(name: "C", pages: 1)
        let pages = [
            PageRef(source: .pdf(url: urlA, pageIndex: 0)),
            PageRef(source: .pdf(url: urlB, pageIndex: 0)),
            PageRef(source: .pdf(url: urlC, pageIndex: 0)),
        ]
        let document = try ReadDocumentBuilder.build(pages: pages)
        XCTAssertEqual(document.pageCount, 3)
        XCTAssertTrue((document.page(at: 0)?.string ?? "").contains("A1"))
        XCTAssertTrue((document.page(at: 1)?.string ?? "").contains("B1"))
        XCTAssertTrue((document.page(at: 2)?.string ?? "").contains("C1"))

        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("folio-read-\(UUID().uuidString).pdf")
        XCTAssertTrue(document.write(to: dest))
        let reopened = try XCTUnwrap(PDFDocument(url: dest))
        XCTAssertEqual(reopened.pageCount, 3)
    }

    func testReadBuilderEmptyThrows() {
        XCTAssertThrowsError(try ReadDocumentBuilder.build(pages: []))
    }

    func testReadBuilderDoesNotMutateCachedSourceRotation() throws {
        let url = try writeFixture(name: "Spin", pages: 1)
        let cached = try PDFIO.document(at: url)
        let live = try XCTUnwrap(cached.page(at: 0))
        let sourceRotation = live.rotation

        var ref = PageRef(source: .pdf(url: url, pageIndex: 0))
        ref.rotate(by: 90)
        let first = try ReadDocumentBuilder.build(pages: [ref])
        XCTAssertEqual(first.page(at: 0)?.rotation, (sourceRotation + 90) % 360)
        XCTAssertEqual(live.rotation, sourceRotation)

        ref.rotate(by: 90)
        XCTAssertEqual(ref.rotation, 180)
        let second = try ReadDocumentBuilder.build(pages: [ref])
        XCTAssertEqual(
            second.page(at: 0)?.rotation,
            (sourceRotation + 180) % 360,
            "a second rebuild must apply workspace rotation to a fresh copy, not 90+180=270"
        )
        XCTAssertEqual(live.rotation, sourceRotation)
    }

    func testReadTokenChangesWithOrderAndRotation() {
        let a = PageRef(source: .blank(size: CGSize(width: 100, height: 100)))
        var b = PageRef(source: .blank(size: CGSize(width: 100, height: 100)))
        let first = ReadDocumentBuilder.token(pages: [a, b])
        XCTAssertEqual(first, ReadDocumentBuilder.token(pages: [a, b]))
        XCTAssertNotEqual(first, ReadDocumentBuilder.token(pages: [b, a]))
        b.rotate(by: 90)
        XCTAssertNotEqual(first, ReadDocumentBuilder.token(pages: [a, b]))
    }

    func testNavigationEmptyIsNoOp() {
        let empty = WorkspaceState()
        XCTAssertEqual(WorkspaceNavigation.apply(.next, to: empty), empty)
        XCTAssertEqual(WorkspaceNavigation.apply(.previous, to: empty), empty)
        XCTAssertEqual(WorkspaceNavigation.apply(.first, to: empty), empty)
        XCTAssertEqual(WorkspaceNavigation.apply(.last, to: empty), empty)
        XCTAssertNil(WorkspaceNavigation.focusedIndex(in: empty))
    }

    func testNavigationClampsAtEnds() {
        var state = WorkspaceState()
        state.append((0..<3).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) })
        let ids = state.pages.map(\.id)
        state.focusedID = ids[0]
        state.selectedIDs = [ids[0]]

        state = WorkspaceNavigation.apply(.previous, to: state)
        XCTAssertEqual(state.focusedID, ids[0])

        state = WorkspaceNavigation.apply(.next, to: state)
        XCTAssertEqual(state.focusedID, ids[1])
        XCTAssertEqual(state.selectedIDs, [ids[1]])

        state = WorkspaceNavigation.apply(.last, to: state)
        XCTAssertEqual(state.focusedID, ids[2])
        state = WorkspaceNavigation.apply(.next, to: state)
        XCTAssertEqual(state.focusedID, ids[2])

        state = WorkspaceNavigation.apply(.first, to: state)
        XCTAssertEqual(state.focusedID, ids[0])
        XCTAssertEqual(WorkspaceNavigation.focusedIndex(in: state), 0)
    }

    func testReaderUsesMultiPageBuilderNotSingleInsert() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let reader = try String(contentsOf: root.appendingPathComponent("Folio/Features/Stage/ReaderView.swift"), encoding: .utf8)
        XCTAssertTrue(reader.contains("ReadDocumentBuilder.build"))
        XCTAssertTrue(reader.contains("singlePageContinuous"))
        XCTAssertFalse(reader.contains("focusedPage(), let pdfPage = try? PDFBuilder.copyPage"))
    }

    func testKeyboardCommandsAreBoundInAppAndStage() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let app = try String(contentsOf: root.appendingPathComponent("Folio/App/FolioApp.swift"), encoding: .utf8)
        XCTAssertTrue(app.contains("nav.next"))
        XCTAssertTrue(app.contains("nav.previous"))
        XCTAssertTrue(app.contains("nav.first"))
        XCTAssertTrue(app.contains("nav.last"))
        XCTAssertTrue(app.contains("keyboardShortcut(\"o\""))
        XCTAssertTrue(app.contains("keyboardShortcut(\"s\""))
        XCTAssertTrue(app.contains("keyboardShortcut(\"1\""))
        XCTAssertTrue(app.contains("keyboardShortcut(\"2\""))
        XCTAssertTrue(app.contains("keyboardShortcut(\"i\""))
        XCTAssertTrue(app.contains("keyboardShortcut(\"k\""))
        XCTAssertTrue(app.contains("keyboardShortcut(\"r\""))
        let stage = try String(contentsOf: root.appendingPathComponent("Folio/Features/Main/ContentView.swift"), encoding: .utf8)
        XCTAssertTrue(stage.contains("onMoveCommand"))
        XCTAssertTrue(stage.contains("navigate(.next)"))
        XCTAssertTrue(stage.contains("navigate(.previous)"))
        XCTAssertTrue(stage.contains("onDeleteCommand"))
    }

    private func writeFixture(name: String, pages: Int) throws -> URL {
        let document = PDFPageGraphics.makeDocument(pageCount: pages, label: name)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("folio-read-src-\(name)-\(UUID().uuidString).pdf")
        guard document.write(to: url) else { throw FolioError.writeFailed }
        return url
    }
}

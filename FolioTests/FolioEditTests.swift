import AppKit
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

    func testReaderScrollDoesNotJumpWhenFocusMatchesVisiblePage() {
        XCTAssertFalse(ReaderFocusPolicy.shouldJump(to: 3, lastVisible: 3, lastApplied: 1))
        XCTAssertFalse(ReaderFocusPolicy.shouldJump(to: 2, lastVisible: 2, lastApplied: 2))
        XCTAssertTrue(ReaderFocusPolicy.shouldJump(to: 2, lastVisible: 1, lastApplied: 1))
        XCTAssertTrue(ReaderFocusPolicy.shouldJump(to: 0, lastVisible: -1, lastApplied: -1))
    }

    func testReaderPageIndexLookup() {
        let ids = [UUID(), UUID(), UUID()]
        XCTAssertEqual(ReaderPageIndex.id(at: 1, in: ids), ids[1])
        XCTAssertNil(ReaderPageIndex.id(at: 9, in: ids))
        XCTAssertEqual(ReaderPageIndex.index(of: ids[2], in: ids), 2)
    }

    func testRevealFromReaderKeepsMultiSelection() {
        let model = AppModel()
        model.workspace.append((0..<4).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) })
        let ids = model.workspace.pages.map(\.id)
        model.workspace.selectedIDs = Set(ids)
        model.workspace.focusedID = ids[0]
        model.revealPageFromReader(ids[2])
        XCTAssertEqual(model.workspace.focusedID, ids[2])
        XCTAssertEqual(model.workspace.selectedIDs, Set(ids))
    }

    func testSelectingEditAgainDoesNotForceReadIfUserLeft() {
        let model = AppModel()
        model.workspace.append([PageRef(source: .blank(size: CGSize(width: 10, height: 10)))])
        model.selectTool(.merge)
        model.stageMode = .pages
        model.selectTool(.edit)
        XCTAssertEqual(model.stageMode, .read)
        model.stageMode = .pages
        model.selectTool(.edit)
        XCTAssertEqual(model.stageMode, .pages)
    }

    func testNativePointerKeepsScrollOnSelectAndHighlight() {
        XCTAssertTrue(EditInteraction.usesNativePointer(.edit, mark: .select))
        XCTAssertTrue(EditInteraction.usesNativePointer(.edit, mark: .highlight))
        XCTAssertTrue(EditInteraction.usesNativePointer(.edit, mark: .underline))
        XCTAssertFalse(EditInteraction.usesNativePointer(.edit, mark: .draw))
        XCTAssertFalse(EditInteraction.usesNativePointer(.redact, mark: .select))
        XCTAssertTrue(EditInteraction.usesNativePointer(.pages, mark: .draw))
    }

    func testAreaCommitIsOnlyForCustomEditTools() {
        XCTAssertFalse(EditInteraction.commitsDragRect(.edit, mark: .select))
        XCTAssertFalse(EditInteraction.commitsDragRect(.edit, mark: .highlight))
        XCTAssertFalse(EditInteraction.commitsDragRect(.edit, mark: .underline))
        XCTAssertTrue(EditInteraction.commitsDragRect(.edit, mark: .draw))
        XCTAssertTrue(EditInteraction.commitsDragRect(.edit, mark: .textBox))
        XCTAssertTrue(EditInteraction.commitsDragRect(.edit, mark: .crop))
        XCTAssertTrue(EditInteraction.commitsDragRect(.redact, mark: .select))
        XCTAssertFalse(EditInteraction.commitsDragRect(.pages, mark: .draw))
    }

    func testPDFHostHasNoIntrinsicDocumentSize() {
        let host = FolioPDFHost(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        XCTAssertEqual(host.intrinsicContentSize.width, NSView.noIntrinsicMetric)
        XCTAssertEqual(host.intrinsicContentSize.height, NSView.noIntrinsicMetric)
        XCTAssertEqual(host.pdfView.intrinsicContentSize.height, NSView.noIntrinsicMetric)
    }

    func testRubberOverlayNeverTakesHits() {
        let overlay = RubberOverlay(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        XCTAssertNil(overlay.hitTest(NSPoint(x: 40, y: 40)))
        XCTAssertFalse(overlay.isOpaque)
    }

    func testReplaceMarkMovesRectAndKeepsIdentity() {
        var state = WorkspaceState()
        var page = PageRef(source: .blank(size: CGSize(width: 200, height: 200)))
        var mark = PageMark(kind: .highlight, rect: CGRect(x: 1, y: 2, width: 30, height: 10))
        page.marks = [mark]
        state.append([page])
        mark.rect = CGRect(x: 40, y: 50, width: 30, height: 10)
        XCTAssertTrue(state.replaceMark(mark))
        XCTAssertEqual(state.pages[0].marks[0].id, mark.id)
        XCTAssertEqual(state.pages[0].marks[0].rect.origin, CGPoint(x: 40, y: 50))
        XCTAssertEqual(state.mark(id: mark.id)?.rect.width, 30)
    }

    func testAppModelReplaceMarkRegistersAsUnsaved() {
        let model = AppModel()
        var page = PageRef(source: .blank(size: CGSize(width: 10, height: 10)))
        var mark = PageMark(kind: .textBox, rect: CGRect(x: 2, y: 2, width: 40, height: 16), text: "Hi")
        page.marks = [mark]
        model.workspace.append([page])
        mark.text = "Hello"
        model.replaceMark(mark)
        XCTAssertTrue(model.hasUnsavedEdits)
        XCTAssertEqual(model.workspace.pages[0].marks[0].text, "Hello")
        XCTAssertEqual(model.selectedMarkID, mark.id)
    }

    func testAnnotationServiceWritesFolioHighlight() {
        let page = PDFPageGraphics.makePage(text: "Hello")
        let mark = PageMark(kind: .highlight, rect: CGRect(x: 70, y: 680, width: 90, height: 18))
        AnnotationService.sync(page: page, marks: [mark], crop: nil)
        XCTAssertEqual(page.annotations.count, 1)
        let annotation = page.annotations[0]
        XCTAssertEqual(annotation.userName, AnnotationService.owner)
        XCTAssertEqual(AnnotationService.markID(from: annotation), mark.id)
        XCTAssertTrue((annotation.type ?? "").localizedCaseInsensitiveContains("highlight"))
    }

    func testAnnotationSyncReplacesPreviousFolioMarks() {
        let page = PDFPageGraphics.makePage(text: "Hello")
        let first = PageMark(kind: .highlight, rect: CGRect(x: 10, y: 10, width: 40, height: 10))
        AnnotationService.sync(page: page, marks: [first], crop: nil)
        let second = PageMark(kind: .underline, rect: CGRect(x: 20, y: 20, width: 50, height: 10))
        AnnotationService.sync(page: page, marks: [second], crop: nil)
        XCTAssertEqual(page.annotations.count, 1)
        XCTAssertEqual(AnnotationService.markID(from: page.annotations[0]), second.id)
    }

    func testRemoveMarkLeavesOtherPagesAlone() {
        var state = WorkspaceState()
        var a = PageRef(source: .blank(size: CGSize(width: 10, height: 10)))
        var b = PageRef(source: .blank(size: CGSize(width: 10, height: 10)))
        let keep = PageMark(kind: .highlight, rect: CGRect(x: 1, y: 1, width: 4, height: 4))
        let gone = PageMark(kind: .highlight, rect: CGRect(x: 1, y: 1, width: 4, height: 4))
        a.marks = [keep]
        b.marks = [gone]
        state.append([a, b])
        XCTAssertTrue(state.removeMark(id: gone.id))
        XCTAssertEqual(state.pages[0].marks.map(\.id), [keep.id])
        XCTAssertTrue(state.pages[1].marks.isEmpty)
    }

    func testDeleteSelectedRemovesMarkInsteadOfPage() {
        let model = AppModel()
        var page = PageRef(source: .blank(size: CGSize(width: 10, height: 10)))
        let mark = PageMark(kind: .highlight, rect: CGRect(x: 1, y: 1, width: 4, height: 4))
        page.marks = [mark]
        model.workspace.append([page])
        model.tool = .edit
        model.selectedMarkID = mark.id
        model.deleteSelected()
        XCTAssertEqual(model.workspace.pages.count, 1)
        XCTAssertTrue(model.workspace.pages[0].marks.isEmpty)
        XCTAssertNil(model.selectedMarkID)
    }

    func testUnflattenedSaveKeepsFolioAnnotations() async throws {
        var page = PageRef(source: .blank(size: CGSize(width: 200, height: 200)))
        page.marks = [PageMark(kind: .highlight, rect: CGRect(x: 20, y: 20, width: 40, height: 12))]
        var options = ExportOptions()
        options.flattenAnnotations = false
        let document = try await PDFBuilder.build(pages: [page], tool: .edit, options: options)
        let built = try XCTUnwrap(document.page(at: 0))
        XCTAssertFalse(built.annotations.isEmpty)
        XCTAssertEqual(built.annotations[0].userName, AnnotationService.owner)
    }

    func testFlattenedSavePaintsMarksWithoutLiveAnnotations() async throws {
        var page = PageRef(source: .blank(size: CGSize(width: 200, height: 200)))
        page.marks = [PageMark(kind: .highlight, rect: CGRect(x: 20, y: 20, width: 40, height: 12))]
        var options = ExportOptions()
        options.flattenAnnotations = true
        let document = try await PDFBuilder.build(pages: [page], tool: .edit, options: options)
        let built = try XCTUnwrap(document.page(at: 0))
        XCTAssertFalse(built.annotations.contains { $0.userName == AnnotationService.owner })
    }

    func testCropApplyDoesNotUseImageImportInset() {
        let page = PDFPageGraphics.makeBlankPage(size: CGSize(width: 400, height: 500))
        let cropped = PDFPageGraphics.crop(page, to: CGRect(x: 40, y: 50, width: 180, height: 220))
        let bounds = cropped.bounds(for: .mediaBox)
        XCTAssertEqual(bounds.width, 180, accuracy: 1)
        XCTAssertEqual(bounds.height, 220, accuracy: 1)
    }

    func testExportDoesNotBecomeTheSilentSaveTarget() async throws {
        let model = AppModel()
        let url = try writeFixture(name: "EXPORT", pages: 1)
        await model.importURLsAsync([url])
        XCTAssertNil(model.lastSaveURL)
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

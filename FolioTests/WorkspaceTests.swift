import XCTest
@testable import Folio

final class WorkspaceTests: XCTestCase {
    func makePages(_ count: Int) -> [PageRef] {
        (0..<count).map { _ in PageRef(source: .blank(size: CGSize(width: 612, height: 792))) }
    }

    func testImportOrder() {
        var state = WorkspaceState()
        let first = makePages(2)
        let second = makePages(1)
        state.append(first)
        state.append(second)
        XCTAssertEqual(state.pages.count, 3)
        XCTAssertEqual(state.pages.map(\.id), first.map(\.id) + second.map(\.id))
        XCTAssertEqual(state.focusedID, first[0].id)
    }

    func testRotateWraps() {
        var state = WorkspaceState()
        state.append(makePages(1))
        state.selectedIDs = [state.pages[0].id]
        state.rotateSelected(by: 90)
        XCTAssertEqual(state.pages[0].rotation, 90)
        state.rotateSelected(by: 90)
        state.rotateSelected(by: 90)
        state.rotateSelected(by: 90)
        XCTAssertEqual(state.pages[0].rotation, 0)
        state.rotateSelected(by: -90)
        XCTAssertEqual(state.pages[0].rotation, 270)
    }

    func testDeleteAndReverse() {
        var state = WorkspaceState()
        state.append(makePages(3))
        let ids = state.pages.map(\.id)
        state.selectedIDs = [ids[1]]
        state.deleteSelected()
        XCTAssertEqual(state.pages.map(\.id), [ids[0], ids[2]])
        state.reverse()
        XCTAssertEqual(state.pages.map(\.id), [ids[2], ids[0]])
    }

    func testMove() {
        var state = WorkspaceState()
        state.append(makePages(3))
        let first = state.pages[0].id
        state.move(id: first, to: 2)
        XCTAssertEqual(state.pages[1].id, first)
    }

    func testNormalizedRotation() {
        XCTAssertEqual(PageRef.normalized(450), 90)
        XCTAssertEqual(PageRef.normalized(-90), 270)
        XCTAssertEqual(PageRef.normalized(0), 0)
    }

    func testDisplayNumber() {
        var options = PageNumberOptions()
        options.format = .of
        options.startAt = 1
        XCTAssertEqual(StampService.displayNumber(index: 0, total: 4, options: options), "1 / 4")
        options.format = .page
        options.startAt = 3
        XCTAssertEqual(StampService.displayNumber(index: 0, total: 4, options: options), "Page 3")
    }

    func testVisionRect() {
        let bounds = CGRect(x: 0, y: 0, width: 100, height: 200)
        let rect = OCRService.visionRect(CGRect(x: 0.1, y: 0.25, width: 0.5, height: 0.1), in: bounds)
        XCTAssertEqual(rect.origin.x, 10, accuracy: 0.01)
        XCTAssertEqual(rect.origin.y, 50, accuracy: 0.01)
        XCTAssertEqual(rect.width, 50, accuracy: 0.01)
        XCTAssertEqual(rect.height, 20, accuracy: 0.01)
    }
}

import XCTest
@testable import Folio

final class RangeParserTests: XCTestCase {
    func testSimpleRange() throws {
        let groups = try PageRangeParser.parse("1-3", pageCount: 12)
        XCTAssertEqual(groups, [[0, 1, 2]])
    }

    func testMixedTokens() throws {
        let groups = try PageRangeParser.parse("1-3, 7, 10-", pageCount: 12)
        XCTAssertEqual(groups, [[0, 1, 2], [6], [9, 10, 11]])
    }

    func testFlattenRanges() throws {
        let groups = try PageRangeParser.parse("1-2, 5", pageCount: 6, oneFilePerRange: false)
        XCTAssertEqual(groups, [[0, 1, 4]])
    }

    func testEmptyThrows() {
        XCTAssertThrowsError(try PageRangeParser.parse("  ", pageCount: 3))
        XCTAssertThrowsError(try PageRangeParser.parse("1-2", pageCount: 0))
    }

    func testInvertedRangeThrows() {
        XCTAssertThrowsError(try PageRangeParser.parse("5-2", pageCount: 10))
    }

    func testOutOfBoundsThrows() {
        XCTAssertThrowsError(try PageRangeParser.parse("14", pageCount: 12)) { error in
            XCTAssertEqual(error as? PageRangeParser.ParseError, .outOfBounds(14))
        }
    }

    func testInvalidTokenThrows() {
        XCTAssertThrowsError(try PageRangeParser.parse("a-b", pageCount: 5))
        XCTAssertThrowsError(try PageRangeParser.parse("1,,2", pageCount: 5))
    }

    func testSplitPlannerEvery() throws {
        let pages = (0..<5).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) }
        let groups = try SplitPlanner.plan(pages: pages, selected: [], mode: .every(2))
        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[0].count, 2)
        XCTAssertEqual(groups[2].count, 1)
    }

    func testSplitPlannerEachPage() throws {
        let pages = (0..<3).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) }
        let groups = try SplitPlanner.plan(pages: pages, selected: [], mode: .eachPage)
        XCTAssertEqual(groups.map(\.count), [1, 1, 1])
    }

    func testSplitPlannerSelectedFallsBackToAll() throws {
        let pages = (0..<2).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) }
        let groups = try SplitPlanner.plan(pages: pages, selected: [], mode: .selected)
        XCTAssertEqual(groups.first?.count, 2)
    }

    func testSplitPlannerEmptyThrows() {
        XCTAssertThrowsError(try SplitPlanner.plan(pages: [], selected: [], mode: .singleFile))
    }
}

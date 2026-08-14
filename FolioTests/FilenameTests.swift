import XCTest
@testable import Folio

final class FilenameTests: XCTestCase {
    func testFirstName() {
        let name = ExportFilename.make(base: "Report", suffix: " – merged", ext: "pdf", existingNames: [])
        XCTAssertEqual(name, "Report – merged.pdf")
    }

    func testCollisionIncrements() {
        let existing: Set<String> = ["Report – merged.pdf"]
        let name = ExportFilename.make(base: "Report", suffix: " – merged", ext: "pdf", existingNames: existing)
        XCTAssertEqual(name, "Report – merged 2.pdf")
    }

    func testSecondCollision() {
        let existing: Set<String> = ["Report – merged.pdf", "Report – merged 2.pdf"]
        let name = ExportFilename.make(base: "Report", suffix: " – merged", ext: "pdf", existingNames: existing)
        XCTAssertEqual(name, "Report – merged 3.pdf")
    }

    func testEmptyBase() {
        let name = ExportFilename.make(base: "", suffix: " – text", ext: ".txt", existingNames: [])
        XCTAssertEqual(name, "Untitled – text.txt")
    }

    func testStemFromURL() {
        let url = URL(fileURLWithPath: "/tmp/Invoice.final.pdf")
        XCTAssertEqual(ExportFilename.stem(from: url), "Invoice.final")
        XCTAssertEqual(ExportFilename.stem(from: nil), "Untitled")
    }

    func testPartSuffix() {
        XCTAssertEqual(ExportFilename.partSuffix(template: " – part", index: 2), " – part 2")
    }
}

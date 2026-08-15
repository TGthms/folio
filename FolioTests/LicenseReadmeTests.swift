import XCTest
@testable import Folio

/// Drives shipped copyright / repo facts from the app bundle.
final class LicenseReadmeTests: XCTestCase {
    func testAppCopyrightNamesTGthmsAndGrok() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(
                forResource: "Localizable",
                withExtension: "strings",
                subdirectory: nil,
                localization: "en"
            )
        )
        let table = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])
        XCTAssertEqual(table["settings.copyright"], "Copyright © 2026 TGthms & Grok")
        XCTAssertFalse((table["pages.selectRangeHint"] ?? "").contains("4-6"))
        XCTAssertEqual(FolioLinks.repository.absoluteString, "https://github.com/TGthms/folio")
    }
}

import XCTest
@testable import Folio

final class LocalizationTests: XCTestCase {
    func testShippedBundleHasEveryLocaleAndKey() throws {
        let bundle = Bundle.main
        let englishURL = try XCTUnwrap(
            bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: "en"),
            "English strings missing from Folio.app"
        )
        let english = try XCTUnwrap(NSDictionary(contentsOf: englishURL) as? [String: String])
        XCTAssertGreaterThan(english.count, 40)

        for code in L10n.supportedCodes {
            let url = try XCTUnwrap(
                bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: code),
                "missing shipped locale \(code)"
            )
            let table = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String], "unreadable \(code)")
            for key in english.keys {
                let value = try XCTUnwrap(table[key], "\(code) missing \(key)")
                XCTAssertFalse(value.isEmpty, "\(code) \(key) is empty")
            }
        }
    }

    func testRTLFlags() {
        XCTAssertTrue(L10n.rtlCodes.contains("ar"))
        XCTAssertTrue(L10n.rtlCodes.contains("he"))
        XCTAssertFalse(L10n.rtlCodes.contains("en"))
        XCTAssertEqual(L10n.supportedCodes.count, 30)
    }

    func testSuffixKeysExistForEveryTool() throws {
        let bundle = Bundle.main
        let englishURL = try XCTUnwrap(
            bundle.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: "en")
        )
        let english = try XCTUnwrap(NSDictionary(contentsOf: englishURL) as? [String: String])
        for tool in Tool.allCases {
            XCTAssertNotNil(english[tool.suffixKey], "missing suffix \(tool.suffixKey)")
            XCTAssertNotNil(english[tool.titleKey], "missing title \(tool.titleKey)")
        }
    }
}

import XCTest

/// Drives the shipped LICENSE and README files in the published tree.
final class LicenseReadmeTests: XCTestCase {
    func testLicenseIsMITAndNamesTGthms() throws {
        let url = repositoryRoot().appendingPathComponent("LICENSE")
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.contains("MIT License"), "LICENSE must be the MIT License")
        XCTAssertTrue(text.contains("TGthms"), "LICENSE must name TGthms")
        XCTAssertTrue(
            text.localizedCaseInsensitiveContains("permission is hereby granted"),
            "LICENSE must grant permission"
        )
        XCTAssertTrue(
            text.localizedCaseInsensitiveContains("without warranty"),
            "LICENSE must include the no-warranty clause"
        )
    }

    func testReadmeSetIsMultilingualAndCoversProductBuildUse() throws {
        let root = repositoryRoot()
        let englishURL = root.appendingPathComponent("README.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: englishURL.path), "README.md missing")

        let extras = try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil
        )
        .filter { url in
            let name = url.lastPathComponent
            return name.hasPrefix("README.") && name.hasSuffix(".md") && name != "README.md"
        }
        XCTAssertFalse(extras.isEmpty, "need at least one non-English README.<lang>.md")

        for url in [englishURL] + extras.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let text = try String(contentsOf: url, encoding: .utf8)
            let name = url.lastPathComponent
            XCTAssertGreaterThan(text.count, 400, "\(name) looks like a stub")
            XCTAssertTrue(text.contains("PDF"), "\(name) missing product (PDF)")
            XCTAssertTrue(
                text.contains("build-app.sh") || text.contains("Folio.xcodeproj"),
                "\(name) missing build instructions"
            )
            XCTAssertTrue(
                text.contains("⌘O") && text.contains("⌘S"),
                "\(name) missing use instructions (open / export)"
            )
        }
    }

    func testGitignoreExcludesBuildProducts() throws {
        let text = try String(
            contentsOf: repositoryRoot().appendingPathComponent(".gitignore"),
            encoding: .utf8
        )
        XCTAssertTrue(text.contains("build/"), ".gitignore must exclude build/")
        XCTAssertTrue(text.contains("DerivedData"), ".gitignore must exclude DerivedData")
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

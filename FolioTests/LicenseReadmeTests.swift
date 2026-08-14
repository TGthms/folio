import XCTest

/// Drives the shipped LICENSE and README files in the published tree.
final class LicenseReadmeTests: XCTestCase {
    func testLicenseIsMITAndNamesTGthms() throws {
        let url = repositoryRoot().appendingPathComponent("LICENSE")
        let text = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(text.contains("MIT License"), "LICENSE must be the MIT License")
        XCTAssertTrue(text.contains("TGthms"), "LICENSE must name TGthms")
        XCTAssertFalse(text.contains("Grok"), "LICENSE must not name Grok")
        XCTAssertTrue(
            text.localizedCaseInsensitiveContains("permission is hereby granted"),
            "LICENSE must grant permission"
        )
        XCTAssertTrue(
            text.localizedCaseInsensitiveContains("without warranty"),
            "LICENSE must include the no-warranty clause"
        )
    }

    func testAppCopyrightNamesTGthmsAndGrok() throws {
        let root = repositoryRoot()
        let plist = try String(
            contentsOf: root.appendingPathComponent("Folio/Resources/Info.plist"),
            encoding: .utf8
        )
        XCTAssertTrue(plist.contains("TGthms"), "Info.plist copyright must name TGthms")
        XCTAssertTrue(plist.contains("Grok"), "Info.plist copyright must name Grok")

        let settings = try String(
            contentsOf: root.appendingPathComponent("Folio/Features/Settings/SettingsView.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(settings.contains("settings.copyright"), "Settings must show the shipped copyright string")

        let sidebar = try String(
            contentsOf: root.appendingPathComponent("Folio/Features/Sidebar/SidebarView.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(sidebar.contains("settings.copyright"), "Sidebar must show the shipped copyright string")

        let english = try String(
            contentsOf: root.appendingPathComponent("scripts/generate_strings.py"),
            encoding: .utf8
        )
        XCTAssertTrue(
            english.contains("Copyright © 2026 TGthms & Grok"),
            "shipped settings.copyright must be TGthms & Grok"
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

import AppKit
import XCTest
@testable import Folio

@MainActor
final class SettingsLanguageAndPagesTests: XCTestCase {
    override func tearDown() {
        L10n.apply(nil)
        super.tearDown()
    }

    func testDoneDismissesSettingsPresentation() {
        let model = AppModel()
        model.settingsPresented = true
        SettingsDismissal.applyAndDismiss(language: "system", model: model)
        XCTAssertFalse(model.settingsPresented, "Done must clear the shared settings presentation flag")
    }

    func testSettingsWindowDetectorMatchesSwiftUISettings() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )
        window.identifier = NSUserInterfaceItemIdentifier("com.apple.SwiftUI.Settings")
        XCTAssertTrue(SettingsDismissal.isSettingsWindow(window))
        let other = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: true
        )
        other.title = "Folio"
        other.identifier = NSUserInterfaceItemIdentifier("main")
        XCTAssertFalse(SettingsDismissal.isSettingsWindow(other))
    }

    func testApplyJapaneseUsesShippedCatalogNotEnglish() throws {
        let english = try shipped("en", "tool.merge")
        let japanese = try shipped("ja", "tool.merge")
        XCTAssertNotEqual(japanese, english, "fixture locales must differ")

        L10n.apply("ja")
        XCTAssertEqual(L10n.catalogCode, "ja")
        XCTAssertEqual(L10n.t("tool.merge"), japanese)
        XCTAssertNotEqual(L10n.t("tool.merge"), english)
        XCTAssertEqual(L10n.t("settings.title"), try shipped("ja", "settings.title"))

        L10n.apply("en")
        XCTAssertEqual(L10n.t("tool.merge"), english)
        XCTAssertEqual(L10n.t("settings.title"), try shipped("en", "settings.title"))
    }

    func testAppModelApplyLanguageDrivesTheSameLookup() throws {
        let model = AppModel()
        let japanese = try shipped("ja", "tool.merge")
        model.applyLanguage("ja")
        XCTAssertEqual(L10n.t("tool.merge"), japanese)
        XCTAssertGreaterThan(model.localeGeneration, 0)
        model.applyLanguage("en")
        XCTAssertEqual(L10n.t("tool.merge"), try shipped("en", "tool.merge"))
    }

    func testResolveMapsRegionalCodesOntoShippedCatalogs() {
        XCTAssertEqual(L10n.resolve("ja-JP"), "ja")
        XCTAssertEqual(L10n.resolve("zh-Hans-CN"), "zh-Hans")
        XCTAssertEqual(L10n.resolve("pt-BR"), "pt-BR")
        XCTAssertEqual(L10n.resolve("en-US"), "en")
    }

    func testSelectRangeFourToSixThenDeleteLeavesFirstThree() throws {
        var state = WorkspaceState()
        state.append((0..<6).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) })
        let original = state.pages.map(\.id)

        state = try PageSelection.select(range: "4-6", in: state)
        let selected = original.indices.filter { state.selectedIDs.contains(original[$0]) }
        XCTAssertEqual(selected, [3, 4, 5])

        state.deleteSelected()
        XCTAssertEqual(state.pages.map(\.id), Array(original.prefix(3)))
    }

    func testSelectRangeEmptyOrOutOfBoundsDoesNotSelectEverything() {
        var state = WorkspaceState()
        state.append((0..<6).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) })
        let before = state
        XCTAssertThrowsError(try PageSelection.select(range: "  ", in: state))
        XCTAssertThrowsError(try PageSelection.select(range: "9-10", in: state))
        XCTAssertEqual(state, before)
        XCTAssertNotEqual(state.selectedIDs.count, state.pages.count)
    }

    func testRangeSelectCopyExplainsWithoutExampleNumbers() throws {
        let english = try shipped("en", "pages.selectRangeHint")
        let help = try shipped("en", "pages.selectRangeHelp")
        XCTAssertFalse(english.contains("4-6"))
        XCTAssertFalse(english.contains("1-6"))
        XCTAssertFalse(help.contains("4-6"))
        XCTAssertTrue(help.localizedCaseInsensitiveContains("range") || help.localizedCaseInsensitiveContains("page"))
        XCTAssertTrue(help.localizedCaseInsensitiveContains("delete") || help.localizedCaseInsensitiveContains("action"))
        XCTAssertEqual(try shipped("en", "pages.selectRange"), "Select")
    }

    func testAppModelSelectPagesThenDeleteUsesShippedPath() {
        let model = AppModel()
        model.workspace.append((0..<6).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) })
        let original = model.workspace.pages.map(\.id)
        model.selectPages(range: "4-6")
        XCTAssertEqual(
            original.indices.filter { model.workspace.selectedIDs.contains(original[$0]) },
            [3, 4, 5]
        )
        model.deleteSelected()
        XCTAssertEqual(model.workspace.pages.map(\.id), Array(original.prefix(3)))
    }

    func testPageReorderMoveAOntoC() {
        let pages = (0..<3).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) }
        let ids = pages.map(\.id)
        let moved = PageReorder.move(pages, id: ids[0], to: 2)
        XCTAssertEqual(moved.map(\.id), [ids[1], ids[0], ids[2]])
    }

    func testPreviewDoesNotMutateWorkspaceUntilCommit() {
        let model = AppModel()
        model.workspace.append((0..<3).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) })
        let original = model.workspace.pages.map(\.id)
        model.draggingPageID = original[0]
        model.previewPageMove(id: original[0], to: 2)
        XCTAssertEqual(model.workspace.pages.map(\.id), original)
        let preview = PageReorder.displayed(
            model.workspace.pages,
            dragging: model.draggingPageID,
            previewDestination: model.dragPreviewDestination
        )
        XCTAssertEqual(preview.map(\.id), [original[1], original[0], original[2]])
        model.commitPageDrag()
        XCTAssertEqual(model.workspace.pages.map(\.id), [original[1], original[0], original[2]])
        XCTAssertNil(model.draggingPageID)
        XCTAssertNil(model.dragPreviewDestination)
    }

    func testCancelPreviewLeavesOrderUnchanged() {
        let model = AppModel()
        model.workspace.append((0..<3).map { _ in PageRef(source: .blank(size: CGSize(width: 10, height: 10))) })
        let original = model.workspace.pages.map(\.id)
        model.draggingPageID = original[0]
        model.previewPageMove(id: original[0], to: 2)
        model.cancelPageDrag()
        XCTAssertEqual(model.workspace.pages.map(\.id), original)
    }

    private func shipped(_ locale: String, _ key: String) throws -> String {
        let url = try XCTUnwrap(
            Bundle.main.url(
                forResource: "Localizable",
                withExtension: "strings",
                subdirectory: nil,
                localization: locale
            )
        )
        let table = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])
        return try XCTUnwrap(table[key], "\(locale) missing \(key)")
    }
}

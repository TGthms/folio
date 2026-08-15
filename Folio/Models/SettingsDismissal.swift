import AppKit
import SwiftUI

/// Shared Done / open path for the in-app sheet and the macOS Settings scene.
enum SettingsDismissal {
    @MainActor
    static func applyAndDismiss(language: String, model: AppModel) {
        dismiss(model)
        model.applyLanguage(language == "system" ? nil : language)
    }

    @MainActor
    static func dismiss(_ model: AppModel) {
        model.settingsPresented = false
        closeSettingsWindows()
    }

    @MainActor
    static func openSettings(model: AppModel) {
        model.settingsPresented = true
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    static func closeSettingsWindows() {
        for window in NSApp.windows where isSettingsWindow(window) {
            window.performClose(nil)
            if window.isVisible {
                window.close()
            }
        }
    }

    static func isSettingsWindow(_ window: NSWindow) -> Bool {
        let identifier = window.identifier?.rawValue ?? ""
        if identifier.localizedCaseInsensitiveContains("settings") { return true }
        let autosave = window.frameAutosaveName
        if autosave.localizedCaseInsensitiveContains("settings") { return true }
        let title = window.title
        if title.localizedCaseInsensitiveContains("settings") { return true }
        if title.localizedCaseInsensitiveContains("preferences") { return true }
        if title == L10n.t("settings.title") { return true }
        return false
    }
}

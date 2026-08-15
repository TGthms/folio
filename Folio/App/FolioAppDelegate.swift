import AppKit

/// Delivers Finder / default-handler file opens to the same import as Add Files and `onOpenURL`.
@MainActor
final class FolioAppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var queued: [URL] = []

    func application(_ application: NSApplication, open urls: [URL]) {
        deliver(urls)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let model, model.hasUnsavedEdits else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = L10n.t("quit.unsaved")
        alert.addButton(withTitle: L10n.t("menu.save"))
        alert.addButton(withTitle: L10n.t("quit.discard"))
        alert.addButton(withTitle: L10n.t("cancel"))
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            Task { @MainActor in
                let saved = await model.saveForTermination()
                NSApp.reply(toApplicationShouldTerminate: saved)
            }
            return .terminateLater
        case .alertSecondButtonReturn:
            return .terminateNow
        default:
            return .terminateCancel
        }
    }

    func attach(_ model: AppModel) {
        self.model = model
        if !queued.isEmpty {
            DocumentOpen.enqueue(queued, into: model)
            queued.removeAll()
        }
    }

    func applyQueued(to model: AppModel) async {
        self.model = model
        let urls = queued
        queued.removeAll()
        if !urls.isEmpty {
            await DocumentOpen.fromExternal(urls, into: model)
        }
    }

    private func deliver(_ urls: [URL]) {
        if let model {
            DocumentOpen.enqueue(urls, into: model)
        } else {
            queued.append(contentsOf: urls)
        }
    }
}

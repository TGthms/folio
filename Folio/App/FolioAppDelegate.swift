import AppKit

/// Delivers Finder / default-handler file opens to the same import as Add Files and `onOpenURL`.
@MainActor
final class FolioAppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var queued: [URL] = []

    func application(_ application: NSApplication, open urls: [URL]) {
        deliver(urls)
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

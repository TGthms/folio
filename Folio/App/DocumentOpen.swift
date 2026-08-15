import Foundation

/// Single entry for Finder / default-handler / `onOpenURL` so one open event cannot import twice.
@MainActor
enum DocumentOpen {
    private static var lastSignature: String?
    private static var lastAt: Date?

    @MainActor
    static func fromExternal(_ urls: [URL], into model: AppModel) async {
        let signature = urls.map { $0.standardizedFileURL.path }.joined(separator: "\n")
        let now = Date()
        if signature == lastSignature, now.timeIntervalSince(lastAt ?? .distantPast) < 0.75 {
            return
        }
        lastSignature = signature
        lastAt = now
        await model.importURLsAsync(urls)
    }

    @MainActor
    static func enqueue(_ urls: [URL], into model: AppModel) {
        Task { await fromExternal(urls, into: model) }
    }

    /// Test hook so a second open after the coalescing window is not blocked.
    static func resetCoalescing() {
        lastSignature = nil
        lastAt = nil
    }
}

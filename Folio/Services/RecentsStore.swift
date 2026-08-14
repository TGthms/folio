import Foundation

struct RecentsStore {
    private let url: URL
    private let limit = 20

    init(fileManager: FileManager = .default) {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let folder = root.appendingPathComponent("Folio", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        url = folder.appendingPathComponent("recents.json")
    }

    func load() -> [RecentItem] {
        guard let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([Record].self, from: data)
        else { return [] }
        return rows.compactMap { record in
            var stale = false
            var resolved: URL?
            resolved = record.bookmark.withUnsafeBytes { raw in
                let bytes = raw.bindMemory(to: UInt8.self)
                let ns = NSData(bytes: bytes.baseAddress, length: bytes.count)
                return try? URL(
                    resolvingBookmarkData: ns as Data,
                    options: [.withSecurityScope, .withoutUI],
                    relativeTo: nil,
                    bookmarkDataIsStale: &stale
                )
            }
            guard let resolved else { return nil }
            return RecentItem(
                id: record.id,
                url: resolved,
                bookmark: record.bookmark,
                lastOpened: record.lastOpened,
                displayName: record.displayName
            )
        }
    }

    func save(_ items: [RecentItem]) {
        let trimmed = Array(items.prefix(limit))
        let rows = trimmed.map {
            Record(id: $0.id, bookmark: $0.bookmark, lastOpened: $0.lastOpened, displayName: $0.displayName)
        }
        if let data = try? JSONEncoder().encode(rows) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func makeItem(for fileURL: URL) -> RecentItem? {
        guard let bookmark = try? fileURL.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return nil }
        return RecentItem(
            id: UUID(),
            url: fileURL,
            bookmark: bookmark,
            lastOpened: Date(),
            displayName: fileURL.lastPathComponent
        )
    }

    private struct Record: Codable {
        var id: UUID
        var bookmark: Data
        var lastOpened: Date
        var displayName: String
    }
}

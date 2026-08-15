import Foundation
import CoreGraphics

struct Redaction: Identifiable, Hashable, Sendable {
    let id: UUID
    var rect: CGRect

    init(id: UUID = UUID(), rect: CGRect) {
        self.id = id
        self.rect = rect
    }
}

enum PageSource: Hashable, Sendable {
    case pdf(url: URL, pageIndex: Int)
    case image(url: URL)
    case blank(size: CGSize)
}

struct PageRef: Identifiable, Hashable, Sendable {
    let id: UUID
    var source: PageSource
    var rotation: Int
    var redactions: [Redaction]
    var marks: [PageMark]
    var cropRect: CGRect?

    init(
        id: UUID = UUID(),
        source: PageSource,
        rotation: Int = 0,
        redactions: [Redaction] = [],
        marks: [PageMark] = [],
        cropRect: CGRect? = nil
    ) {
        self.id = id
        self.source = source
        self.rotation = Self.normalized(rotation)
        self.redactions = redactions
        self.marks = marks
        self.cropRect = cropRect
    }

    var hasEdits: Bool { !marks.isEmpty || cropRect != nil }

    mutating func rotate(by degrees: Int) {
        rotation = Self.normalized(rotation + degrees)
    }

    var sourceURL: URL? {
        switch source {
        case .pdf(let url, _), .image(let url):
            return url
        case .blank:
            return nil
        }
    }

    static func normalized(_ degrees: Int) -> Int {
        var value = degrees % 360
        if value < 0 { value += 360 }
        return value
    }
}

struct SourceDocument: Hashable, Sendable {
    var url: URL
    var pageCount: Int
    var fileSize: Int64
    var isEncrypted: Bool
    var password: String?
}

struct RecentItem: Identifiable, Hashable, Sendable {
    var id: UUID
    var url: URL
    var bookmark: Data
    var lastOpened: Date
    var displayName: String
}

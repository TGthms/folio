import CoreGraphics
import Foundation

enum PageMarkKind: String, Sendable, Hashable {
    case highlight
    case underline
    case textBox
    case stroke
}

struct PageMark: Identifiable, Hashable, Sendable {
    let id: UUID
    var kind: PageMarkKind
    var rect: CGRect
    var points: [CGPoint]
    var text: String

    init(
        id: UUID = UUID(),
        kind: PageMarkKind,
        rect: CGRect,
        points: [CGPoint] = [],
        text: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.rect = rect
        self.points = points
        self.text = text
    }
}

enum EditMarkKind: String, CaseIterable, Identifiable, Sendable {
    case select
    case highlight
    case underline
    case textBox
    case draw
    case crop

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .select: return "edit.select"
        case .highlight: return "edit.highlight"
        case .underline: return "edit.underline"
        case .textBox: return "edit.textBox"
        case .draw: return "edit.draw"
        case .crop: return "edit.cropMode"
        }
    }

    var markKind: PageMarkKind? {
        switch self {
        case .select, .crop: return nil
        case .highlight: return .highlight
        case .underline: return .underline
        case .textBox: return .textBox
        case .draw: return .stroke
        }
    }
}

enum EditInteraction {
    /// Highlight / underline / select use PDFView’s own pointer so the document still scrolls.
    static func usesNativePointer(_ tool: Tool, mark: EditMarkKind) -> Bool {
        switch tool {
        case .redact:
            return false
        case .edit:
            switch mark {
            case .select, .highlight, .underline:
                return true
            case .textBox, .draw, .crop:
                return false
            }
        default:
            return true
        }
    }
}

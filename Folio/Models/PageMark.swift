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

    var symbol: String {
        switch self {
        case .select: return "cursorarrow"
        case .highlight: return "highlighter"
        case .underline: return "underline"
        case .textBox: return "character.textbox"
        case .draw: return "pencil.tip"
        case .crop: return "crop"
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
    /// Select / highlight / underline use PDFView’s own pointer so scroll and text selection stay native.
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

    /// Rubber-band commits are only for draw / text / crop / redact — never a fake highlight box.
    static func commitsDragRect(_ tool: Tool, mark: EditMarkKind) -> Bool {
        switch tool {
        case .redact:
            return true
        case .edit:
            switch mark {
            case .textBox, .draw, .crop:
                return true
            case .select, .highlight, .underline:
                return false
            }
        default:
            return false
        }
    }
}

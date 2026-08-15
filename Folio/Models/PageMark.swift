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
    case highlight
    case underline
    case textBox
    case draw
    case crop

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .highlight: return "edit.highlight"
        case .underline: return "edit.underline"
        case .textBox: return "edit.textBox"
        case .draw: return "edit.draw"
        case .crop: return "edit.cropMode"
        }
    }

    var markKind: PageMarkKind? {
        switch self {
        case .highlight: return .highlight
        case .underline: return .underline
        case .textBox: return .textBox
        case .draw: return .stroke
        case .crop: return nil
        }
    }
}

import Foundation

/// Decides when Read should jump the PDF view.
/// Scroll reports the visible page; that must not send the document back.
enum ReaderFocusPolicy {
    static func shouldJump(to focused: Int, lastVisible: Int, lastApplied: Int) -> Bool {
        guard focused >= 0 else { return false }
        if focused == lastVisible { return false }
        if focused == lastApplied { return false }
        return true
    }
}

enum ReaderPageIndex {
    static func id(at index: Int, in ids: [UUID]) -> UUID? {
        ids.indices.contains(index) ? ids[index] : nil
    }

    static func index(of id: UUID, in ids: [UUID]) -> Int? {
        ids.firstIndex(of: id)
    }
}

enum EditGestureMath {
    static func rect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    static func isCommitable(_ rect: CGRect) -> Bool {
        rect.width > 4 && rect.height > 4
    }

    static func strokeBounds(_ points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .null }
        var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
        for point in points.dropFirst() {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }
        return CGRect(x: minX, y: minY, width: max(1, maxX - minX), height: max(1, maxY - minY))
    }
}

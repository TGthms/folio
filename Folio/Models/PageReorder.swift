import Foundation

/// Pure page-list move used by the tray preview and the committed drop.
enum PageReorder {
    /// Moves `id` so it occupies `destination` in the same way `WorkspaceState.move` always has.
    /// Dragging A (0) onto C (2) in [A,B,C] yields [B,A,C].
    static func move(_ pages: [PageRef], id: UUID, to destination: Int) -> [PageRef] {
        guard let current = pages.firstIndex(where: { $0.id == id }) else { return pages }
        var dest = destination
        if current < dest { dest -= 1 }
        dest = max(0, min(dest, pages.count - 1))
        if dest == current { return pages }
        var next = pages
        let page = next.remove(at: current)
        next.insert(page, at: dest)
        return next
    }

    static func displayed(_ pages: [PageRef], dragging: UUID?, previewDestination: Int?) -> [PageRef] {
        guard let dragging, let previewDestination else { return pages }
        return move(pages, id: dragging, to: previewDestination)
    }
}

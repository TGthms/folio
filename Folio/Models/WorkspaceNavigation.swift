import Foundation

enum WorkspaceNavCommand: String, CaseIterable, Sendable {
    case next
    case previous
    case first
    case last
}

enum WorkspaceNavigation {
    /// Clamps at the ends. Empty workspace is a no-op.
    static func apply(_ command: WorkspaceNavCommand, to state: WorkspaceState) -> WorkspaceState {
        var next = state
        guard !state.pages.isEmpty else { return next }
        let ids = state.pages.map(\.id)
        let current = state.focusedID.flatMap { id in ids.firstIndex(of: id) } ?? 0
        let index: Int
        switch command {
        case .next:
            index = min(current + 1, ids.count - 1)
        case .previous:
            index = max(current - 1, 0)
        case .first:
            index = 0
        case .last:
            index = ids.count - 1
        }
        next.focusedID = ids[index]
        next.selectedIDs = [ids[index]]
        return next
    }

    static func focusedIndex(in state: WorkspaceState) -> Int? {
        guard !state.pages.isEmpty else { return nil }
        if let id = state.focusedID, let index = state.pages.firstIndex(where: { $0.id == id }) {
            return index
        }
        return 0
    }
}

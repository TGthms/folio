import Foundation

/// Selects workspace pages from a 1-based range string such as `4-6`.
enum PageSelection {
    static func select(range: String, in state: WorkspaceState) throws -> WorkspaceState {
        let groups = try PageRangeParser.parse(
            range,
            pageCount: state.pages.count,
            oneFilePerRange: false
        )
        let indices = groups.flatMap { $0 }
        guard !indices.isEmpty else { throw PageRangeParser.ParseError.empty }
        var next = state
        next.selectedIDs = Set(indices.map { state.pages[$0].id })
        if let last = indices.last {
            next.focusedID = state.pages[last].id
        }
        return next
    }
}

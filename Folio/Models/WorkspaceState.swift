import Foundation
import CoreGraphics

struct WorkspaceState: Equatable, Sendable {
    var pages: [PageRef] = []
    var selectedIDs: Set<UUID> = []
    var focusedID: UUID?

    mutating func append(_ newPages: [PageRef]) {
        pages.append(contentsOf: newPages)
        if focusedID == nil {
            focusedID = pages.first?.id
        }
    }

    mutating func rotateSelected(by degrees: Int) {
        let targets = effectiveSelection()
        for index in pages.indices where targets.contains(pages[index].id) {
            pages[index].rotate(by: degrees)
        }
    }

    mutating func deleteSelected() {
        let targets = effectiveSelection()
        pages.removeAll { targets.contains($0.id) }
        selectedIDs.subtract(targets)
        if let focusedID, targets.contains(focusedID) {
            self.focusedID = pages.first?.id
        }
    }

    mutating func reverse() {
        pages.reverse()
    }

    mutating func duplicateSelected() {
        let targets = effectiveSelection()
        var inserted: [PageRef] = []
        var index = 0
        while index < pages.count {
            if targets.contains(pages[index].id) {
                var copy = pages[index]
                copy = PageRef(
                    source: copy.source,
                    rotation: copy.rotation,
                    redactions: copy.redactions,
                    marks: copy.marks,
                    cropRect: copy.cropRect
                )
                pages.insert(copy, at: index + 1)
                inserted.append(copy)
                index += 2
            } else {
                index += 1
            }
        }
        if !inserted.isEmpty {
            selectedIDs = Set(inserted.map(\.id))
            focusedID = inserted.last?.id
        }
    }

    mutating func insertBlank(at index: Int, size: CGSize = CGSize(width: 612, height: 792)) {
        let page = PageRef(source: .blank(size: size))
        let clamped = max(0, min(index, pages.count))
        pages.insert(page, at: clamped)
        selectedIDs = [page.id]
        focusedID = page.id
    }

    mutating func move(from offsets: IndexSet, to destination: Int) {
        pages.move(fromOffsets: offsets, toOffset: destination)
    }

    mutating func move(id: UUID, to destination: Int) {
        pages = PageReorder.move(pages, id: id, to: destination)
    }

    mutating func redactSelectedPages() {
        let targets = effectiveSelection()
        for index in pages.indices where targets.contains(pages[index].id) {
            pages[index].redactions = [Redaction(rect: CGRect(x: 0, y: 0, width: 10_000, height: 10_000))]
        }
    }

    mutating func addRedaction(_ redaction: Redaction, to id: UUID) {
        guard let index = pages.firstIndex(where: { $0.id == id }) else { return }
        pages[index].redactions.append(redaction)
    }

    mutating func addMark(_ mark: PageMark, to id: UUID) {
        guard let index = pages.firstIndex(where: { $0.id == id }) else { return }
        pages[index].marks.append(mark)
    }

    mutating func setCrop(_ rect: CGRect?, on targets: Set<UUID>) {
        for index in pages.indices where targets.contains(pages[index].id) {
            pages[index].cropRect = rect
        }
    }

    mutating func replaceSource(_ source: PageSource, on id: UUID) {
        guard let index = pages.firstIndex(where: { $0.id == id }) else { return }
        pages[index].source = source
        pages[index].rotation = 0
        pages[index].redactions = []
        pages[index].marks = []
        pages[index].cropRect = nil
    }

    mutating func clearMarks(on targets: Set<UUID>) {
        for index in pages.indices where targets.contains(pages[index].id) {
            pages[index].marks = []
        }
    }

    @discardableResult
    mutating func removeMark(id: UUID) -> Bool {
        var removed = false
        for index in pages.indices {
            let before = pages[index].marks.count
            pages[index].marks.removeAll { $0.id == id }
            if pages[index].marks.count != before { removed = true }
        }
        return removed
    }

    @discardableResult
    mutating func replaceMark(_ mark: PageMark) -> Bool {
        for index in pages.indices {
            if let markIndex = pages[index].marks.firstIndex(where: { $0.id == mark.id }) {
                pages[index].marks[markIndex] = mark
                return true
            }
        }
        return false
    }

    func mark(id: UUID) -> PageMark? {
        pages.lazy.flatMap(\.marks).first { $0.id == id }
    }

    mutating func selectAll() {
        selectedIDs = Set(pages.map(\.id))
    }

    func effectiveSelection() -> Set<UUID> {
        if selectedIDs.isEmpty, let focusedID {
            return [focusedID]
        }
        if selectedIDs.isEmpty, let first = pages.first?.id {
            return [first]
        }
        return selectedIDs
    }

    func selectedPages() -> [PageRef] {
        let targets = effectiveSelection()
        let picked = pages.filter { targets.contains($0.id) }
        return picked.isEmpty ? pages : picked
    }
}

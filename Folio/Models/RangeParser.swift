import Foundation

enum PageRangeParser {
    enum ParseError: Error, Equatable, Sendable {
        case empty
        case invalidToken(String)
        case outOfBounds(Int)
    }

    /// Parses a 1-based range string into groups of 0-based page indices.
    /// Examples with pageCount 12: `"1-3, 7, 10-"` → `[[0,1,2],[6],[9,10,11]]`.
    static func parse(_ input: String, pageCount: Int, oneFilePerRange: Bool = true) throws -> [[Int]] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ParseError.empty }
        guard pageCount > 0 else { throw ParseError.empty }

        var groups: [[Int]] = []
        let tokens = trimmed.split(separator: ",", omittingEmptySubsequences: false)
        for raw in tokens {
            let token = raw.trimmingCharacters(in: .whitespaces)
            if token.isEmpty { throw ParseError.invalidToken(token) }

            if token.hasSuffix("-"), !token.dropLast().contains("-") {
                let startToken = token.dropLast().trimmingCharacters(in: .whitespaces)
                guard let start = Int(startToken) else { throw ParseError.invalidToken(token) }
                try validate(start, pageCount: pageCount)
                groups.append(Array((start - 1)..<pageCount))
            } else if let dash = token.firstIndex(of: "-"), dash != token.startIndex, dash != token.index(before: token.endIndex) {
                let startToken = token[..<dash].trimmingCharacters(in: .whitespaces)
                let endToken = token[token.index(after: dash)...].trimmingCharacters(in: .whitespaces)
                guard let start = Int(startToken), let end = Int(endToken) else {
                    throw ParseError.invalidToken(token)
                }
                if start > end { throw ParseError.invalidToken(token) }
                try validate(start, pageCount: pageCount)
                try validate(end, pageCount: pageCount)
                groups.append(Array((start - 1)..<end))
            } else {
                guard let number = Int(token) else { throw ParseError.invalidToken(token) }
                try validate(number, pageCount: pageCount)
                groups.append([number - 1])
            }
        }

        if groups.isEmpty { throw ParseError.empty }
        if oneFilePerRange {
            return groups
        }
        return [groups.flatMap { $0 }]
    }

    private static func validate(_ oneBased: Int, pageCount: Int) throws {
        if oneBased < 1 || oneBased > pageCount {
            throw ParseError.outOfBounds(oneBased)
        }
    }
}

enum SplitPlanner {
    enum Mode: Equatable, Sendable {
        case selected
        case ranges(String, oneFilePerRange: Bool)
        case every(Int)
        case eachPage
        case singleFile
    }

    static func plan(pages: [PageRef], selected: Set<UUID>, mode: Mode) throws -> [[PageRef]] {
        guard !pages.isEmpty else { throw FolioError.emptyWorkspace }
        switch mode {
        case .singleFile:
            return [pages]
        case .selected:
            let picked = pages.filter { selected.contains($0.id) }
            if picked.isEmpty { return [pages] }
            return [picked]
        case .ranges(let string, let oneFilePerRange):
            let groups = try PageRangeParser.parse(string, pageCount: pages.count, oneFilePerRange: oneFilePerRange)
            return groups.map { $0.compactMap { idx in pages.indices.contains(idx) ? pages[idx] : nil } }
        case .every(let n):
            guard n > 0 else { throw FolioError.invalidRange }
            var groups: [[PageRef]] = []
            var index = 0
            while index < pages.count {
                let end = min(index + n, pages.count)
                groups.append(Array(pages[index..<end]))
                index = end
            }
            return groups
        case .eachPage:
            return pages.map { [$0] }
        }
    }
}

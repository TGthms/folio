import Foundation

enum ExportFilename {
    static func stem(from url: URL?) -> String {
        guard let url else { return "Untitled" }
        let name = url.deletingPathExtension().lastPathComponent
        return name.isEmpty ? "Untitled" : name
    }

    /// Builds a filename that does not collide with `existingNames`.
    /// First file is `base + suffix + .ext`; further collisions append ` 2`, ` 3`, …
    static func make(base: String, suffix: String, ext: String, existingNames: Set<String>) -> String {
        let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
        let safeBase = base.isEmpty ? "Untitled" : base
        func name(_ n: Int) -> String {
            if n <= 1 {
                return "\(safeBase)\(suffix).\(cleanExt)"
            }
            return "\(safeBase)\(suffix) \(n).\(cleanExt)"
        }
        var n = 1
        var candidate = name(1)
        while existingNames.contains(candidate) {
            n += 1
            candidate = name(n)
        }
        return candidate
    }

    static func namesOnDisk(in directory: URL) -> Set<String> {
        let items = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        return Set(items)
    }

    static func partSuffix(template: String, index: Int) -> String {
        "\(template) \(index)"
    }
}

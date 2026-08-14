import AppKit
import Foundation
import PDFKit

@main
enum WriteReadFixture {
    static func main() async {
        do {
            try await run()
        } catch {
            fputs("READ_FIXTURE_FAIL \(error)\n", stderr)
            exit(1)
        }
    }

    @MainActor
    private static func run() async throws {
        let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1
            ? CommandLine.arguments[1]
            : FileManager.default.temporaryDirectory.path, isDirectory: true)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        var pages: [PageRef] = []
        for label in ["A", "B", "C"] {
            let doc = PDFPageGraphics.makeDocument(pageCount: 1, label: label)
            let url = outDir.appendingPathComponent("read-src-\(label).pdf")
            guard doc.write(to: url) else { throw FolioError.writeFailed }
            pages.append(PageRef(source: .pdf(url: url, pageIndex: 0)))
        }
        let assembled = try ReadDocumentBuilder.build(pages: pages)
        precondition(assembled.pageCount == 3)
        let dest = outDir.appendingPathComponent("read-three.pdf")
        guard assembled.write(to: dest) else { throw FolioError.writeFailed }
        print("READ_OK \(dest.path) pages=\(assembled.pageCount)")
    }
}

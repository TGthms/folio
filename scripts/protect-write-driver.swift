import AppKit
import Foundation
import PDFKit

/// Host-independent driver: calls shipped `PDFIO.write` with a user password.
@main
enum ProtectWriteDriver {
    static func main() async {
        do {
            try await run()
        } catch {
            fputs("PROTECT_FAIL \(error)\n", stderr)
            exit(1)
        }
    }

    @MainActor
    private static func run() async throws {
        let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1
            ? CommandLine.arguments[1]
            : FileManager.default.temporaryDirectory.path, isDirectory: true)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let source = PDFPageGraphics.makeDocument(pageCount: 1, label: "Private")
        var options = ExportOptions()
        options.userPassword = "open-me"
        options.ownerPassword = "owner-key"
        let dest = outDir.appendingPathComponent("locked.pdf")
        try await PDFIO.write(source, to: dest, options: options, applyOCROption: false)

        guard let locked = PDFDocument(data: try Data(contentsOf: dest)), locked.isLocked else {
            fputs("PROTECT_FAIL file is not locked\n", stderr)
            exit(2)
        }
        guard !locked.unlock(withPassword: "") else {
            fputs("PROTECT_FAIL empty password opened the file\n", stderr)
            exit(3)
        }
        guard !locked.unlock(withPassword: "wrong-password") else {
            fputs("PROTECT_FAIL wrong password opened the file\n", stderr)
            exit(4)
        }
        guard locked.unlock(withPassword: "open-me") else {
            fputs("PROTECT_FAIL correct password rejected\n", stderr)
            exit(5)
        }
        print("PROTECT_OK \(dest.path)")
    }
}

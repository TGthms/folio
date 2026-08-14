import AppKit
import Foundation
import PDFKit

@main
enum VerifyExportPaths {
    static func main() throws {
        let scratch = URL(fileURLWithPath: CommandLine.arguments.count > 1
            ? CommandLine.arguments[1]
            : FileManager.default.temporaryDirectory.path)
        try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)

        fputs("step merge\n", stderr)
        let urlA = scratch.appendingPathComponent("src-A.pdf")
        let urlB = scratch.appendingPathComponent("src-B.pdf")
        guard PDFPageGraphics.makeDocument(pageCount: 1, label: "Alpha").write(to: urlA) else { fatalError("write A") }
        guard PDFPageGraphics.makeDocument(pageCount: 1, label: "Beta").write(to: urlB) else { fatalError("write B") }

        let merged = PDFDocument()
        merged.insert(PDFDocument(url: urlA)!.page(at: 0)!, at: 0)
        merged.insert(PDFDocument(url: urlB)!.page(at: 0)!, at: 1)
        precondition(merged.pageCount == 2)
        precondition((merged.page(at: 0)?.string ?? "").contains("Alpha1"))
        precondition((merged.page(at: 1)?.string ?? "").contains("Beta1"))
        let mergedURL = scratch.appendingPathComponent("merged.pdf")
        guard merged.write(to: mergedURL) else { fatalError("write merge") }
        precondition(PDFDocument(url: mergedURL)!.pageCount == 2)

        fputs("step redact\n", stderr)
        let secretURL = scratch.appendingPathComponent("src-secret.pdf")
        guard PDFPageGraphics.makeDocument(pageCount: 1, label: "SECRETWORD").write(to: secretURL) else { fatalError("write secret") }
        let secretPage = PDFDocument(url: secretURL)!.page(at: 0)!
        let burned = RedactService.burn(
            secretPage,
            redactions: [Redaction(rect: CGRect(x: 0, y: 0, width: 2000, height: 2000))],
            fill: .black
        )
        precondition(!TextService.extract(from: [burned]).contains("SECRETWORD"), "redact failed")
        precondition((PDFDocument(url: secretURL)!.page(at: 0)?.string ?? "").contains("SECRETWORD"), "source mutated")
        let redactedDoc = PDFDocument()
        redactedDoc.insert(burned, at: 0)
        let redactedURL = scratch.appendingPathComponent("redacted.pdf")
        guard redactedDoc.write(to: redactedURL) else { fatalError("write redact") }

        fputs("step protect\n", stderr)
        let privateURL = scratch.appendingPathComponent("src-private.pdf")
        guard PDFPageGraphics.makeDocument(pageCount: 1, label: "Private").write(to: privateURL) else { fatalError("write private") }
        let protectSource = PDFDocument(url: privateURL)!
        guard let payload = protectSource.dataRepresentation(),
              let protectDoc = PDFDocument(data: payload)
        else { fatalError("detach private") }
        let lockedURL = scratch.appendingPathComponent("locked.pdf")
        let ok = protectDoc.write(to: lockedURL, withOptions: [
            .userPasswordOption: "open-me",
            .ownerPasswordOption: "owner-key",
        ])
        guard ok else { fatalError("protect write failed") }
        let locked = PDFDocument(data: try Data(contentsOf: lockedURL))!
        guard locked.isLocked else { fatalError("not locked") }
        guard !locked.unlock(withPassword: "wrong") else { fatalError("wrong password accepted") }
        guard locked.unlock(withPassword: "open-me") else { fatalError("right password rejected") }
        let unlockedText = locked.page(at: 0)?.string ?? ""
        guard unlockedText.contains("Private1") else { fatalError("lost text: \(unlockedText)") }

        FileHandle.standardError.write(Data("ok merge\n".utf8))
        print("VERIFY_OK merge=\(mergedURL.path)")
        print("VERIFY_OK redact=\(redactedURL.path)")
        print("VERIFY_OK locked=\(lockedURL.path)")
    }
}

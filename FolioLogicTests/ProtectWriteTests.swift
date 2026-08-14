import PDFKit
import XCTest

/// Host-independent: runs the prebuilt CLI compiled from shipped `PDFIO.swift`.
/// In-process PDFKit password writes deadlock inside xctest / Folio.app.
final class ProtectWriteTests: XCTestCase {
    func testProtectWriteLocksFileWithoutPassword() throws {
        let project = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let driver = project.appendingPathComponent("build/protect-write-driver")
        XCTAssertTrue(
            FileManager.default.isExecutableFile(atPath: driver.path),
            "missing \(driver.path); run scripts/run-protect-write-driver.sh"
        )

        let out = FileManager.default.temporaryDirectory
            .appendingPathComponent("folio-logic-protect-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = driver
        process.arguments = [out.path]
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        process.waitUntilExit()

        let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let log = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        XCTAssertEqual(process.terminationStatus, 0, "\(err)\n\(log)")
        XCTAssertTrue(log.contains("PROTECT_OK"), log)

        let dest = out.appendingPathComponent("locked.pdf")
        let locked = try XCTUnwrap(PDFDocument(data: try Data(contentsOf: dest)))
        XCTAssertTrue(locked.isLocked)
        XCTAssertFalse(locked.unlock(withPassword: ""))
        XCTAssertTrue(locked.unlock(withPassword: "open-me"))
        XCTAssertTrue((locked.page(at: 0)?.string ?? "").contains("Private1"))
    }
}

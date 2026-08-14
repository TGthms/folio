import AppKit
import CoreText
import PDFKit
import Vision

enum OCRService {
    struct Observation: Sendable {
        var text: String
        var box: CGRect
    }

    static func recognize(on image: NSImage) async throws -> [Observation] {
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return [] }
        return try await recognize(on: cg)
    }

    static func recognize(on image: CGImage) async throws -> [Observation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation] ?? []).compactMap { item -> Observation? in
                    guard let text = item.topCandidates(1).first?.string else { return nil }
                    return Observation(text: text, box: item.boundingBox)
                }
                continuation.resume(returning: observations)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    static func makeSearchable(page: PDFPage, observations: [Observation]) -> PDFPage {
        let bounds = page.bounds(for: .mediaBox)
        return PDFPageGraphics.redraw(page) { ctx, box in
            ctx.saveGState()
            ctx.setTextDrawingMode(.invisible)
            for item in observations {
                let rect = visionRect(item.box, in: bounds)
                guard !item.text.isEmpty, rect.width > 1, rect.height > 1 else { continue }
                let fontSize = max(6, rect.height * 0.85)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: fontSize),
                    .foregroundColor: NSColor.clear,
                ]
                let line = CTLineCreateWithAttributedString(NSAttributedString(string: item.text, attributes: attrs))
                ctx.textPosition = CGPoint(x: rect.minX, y: rect.minY + 1)
                CTLineDraw(line, ctx)
            }
            ctx.restoreGState()
        }
    }

    static func rasterPreview(of page: PDFPage, dpi: CGFloat = 144) -> NSImage {
        let bounds = page.bounds(for: .mediaBox)
        let scale = dpi / 72
        let size = CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale))
        let image = NSImage(size: size)
        image.lockFocus()
        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.scaleBy(x: scale, y: scale)
            ctx.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)
            page.draw(with: .mediaBox, to: ctx)
        }
        image.unlockFocus()
        return image
    }

    static func visionRect(_ normalized: CGRect, in bounds: CGRect) -> CGRect {
        CGRect(
            x: bounds.minX + normalized.minX * bounds.width,
            y: bounds.minY + normalized.minY * bounds.height,
            width: normalized.width * bounds.width,
            height: normalized.height * bounds.height
        )
    }
}

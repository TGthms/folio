import AppKit
import PDFKit

enum PDFBuilder {
    struct Result: Sendable {
        var data: Data
        var pageCount: Int
    }

    @MainActor
    static func build(
        pages: [PageRef],
        tool: Tool,
        options: ExportOptions,
        progress: ((Double) -> Void)? = nil
    ) async throws -> PDFDocument {
        guard !pages.isEmpty else { throw FolioError.emptyWorkspace }
        let document = PDFDocument()
        let total = pages.count
        for (index, ref) in pages.enumerated() {
            try Task.checkCancellation()
            let canvas = tool == .imagesToPDF ? options.imagePageSize.size : nil
            var page = try copyPage(ref, imageCanvas: canvas)
            page.rotation = (page.rotation + ref.rotation) % 360

            if tool == .redact || !ref.redactions.isEmpty {
                page = RedactService.burn(page, redactions: ref.redactions, fill: options.redactFill)
            }
            if ref.hasEdits {
                page = MarkService.apply(
                    page,
                    marks: ref.marks,
                    crop: ref.cropRect,
                    flatten: options.flattenAnnotations
                )
            }

            if tool == .compress {
                if options.compress == .high {
                    if options.grayscale {
                        page = CompressService.applyGrayscale(page)
                    }
                } else if CompressService.shouldRasterize(page, preset: options.compress) || options.grayscale {
                    page = CompressService.rasterize(
                        page,
                        dpi: options.compress.dpi,
                        quality: options.compress.jpegQuality,
                        grayscale: options.grayscale
                    )
                }
            } else if options.grayscale {
                page = CompressService.applyGrayscale(page)
            }

            if tool == .watermark {
                page = StampService.applyWatermark(page, options: options.watermark)
            }

            if tool == .pageNumbers {
                if !(options.pageNumbers.skipFirst && index == 0) {
                    let label = StampService.displayNumber(index: index, total: total, options: options.pageNumbers)
                    page = StampService.applyPageNumber(page, display: label, options: options.pageNumbers)
                }
            }

            if tool == .ocr, !TextService.pageHasText(page) {
                let preview = OCRService.rasterPreview(of: page)
                if let observations = try? await OCRService.recognize(on: preview), !observations.isEmpty {
                    page = OCRService.makeSearchable(page: page, observations: observations)
                }
            }

            document.insert(page, at: document.pageCount)
            progress?(Double(index + 1) / Double(total))
        }
        return document
    }

    @MainActor
    static func copyPage(_ ref: PageRef, imageCanvas: CGSize? = nil) throws -> PDFPage {
        let original = try PDFIO.page(for: ref, imageCanvas: imageCanvas)
        return try PDFPageIsolation.detached(original)
    }

    @MainActor
    static func data(
        pages: [PageRef],
        tool: Tool,
        options: ExportOptions
    ) async throws -> Data {
        let document = try await build(pages: pages, tool: tool, options: options)
        guard let data = document.dataRepresentation() else { throw FolioError.writeFailed }
        return data
    }
}

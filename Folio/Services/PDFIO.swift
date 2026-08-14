import AppKit
import PDFKit

@MainActor
enum PDFIO {
    private static var cache: [URL: PDFDocument] = [:]
    private static var passwords: [URL: String] = [:]

    static func password(for url: URL) -> String? {
        passwords[url]
    }

    static func rememberPassword(_ password: String, for url: URL) {
        passwords[url] = password
        if let document = cache[url], document.isLocked {
            _ = document.unlock(withPassword: password)
        }
    }

    static func evict(_ url: URL) {
        cache.removeValue(forKey: url)
    }

    static func document(at url: URL, password: String? = nil) throws -> PDFDocument {
        if let cached = cache[url] {
            if cached.isLocked {
                let attempt = password ?? passwords[url]
                if let attempt, cached.unlock(withPassword: attempt) {
                    passwords[url] = attempt
                    return cached
                }
                throw FolioError.encrypted
            }
            return cached
        }
        guard let document = PDFDocument(url: url) else {
            throw FolioError.unreadable(url.lastPathComponent)
        }
        if document.isLocked {
            let attempt = password ?? passwords[url]
            if let attempt, document.unlock(withPassword: attempt) {
                passwords[url] = attempt
            } else {
                cache[url] = document
                throw FolioError.encrypted
            }
        }
        cache[url] = document
        return document
    }

    static func page(for ref: PageRef, imageCanvas: CGSize? = nil) throws -> PDFPage {
        switch ref.source {
        case .pdf(let url, let index):
            let document = try document(at: url)
            guard let page = document.page(at: index) else {
                throw FolioError.unreadable(url.lastPathComponent)
            }
            return page
        case .image(let url):
            guard let image = NSImage(contentsOf: url) else {
                throw FolioError.unreadable(url.lastPathComponent)
            }
            return PDFPageGraphics.pageFromImage(image, canvas: imageCanvas)
        case .blank(let size):
            return PDFPageGraphics.makeBlankPage(size: size)
        }
    }

    static func write(_ document: PDFDocument, to url: URL, options: ExportOptions, applyOCROption: Bool) async throws {
        if !options.metadata.title.isEmpty || !options.metadata.author.isEmpty || !options.metadata.subject.isEmpty {
            var attributes = document.documentAttributes ?? [:]
            if !options.metadata.title.isEmpty {
                attributes[PDFDocumentAttribute.titleAttribute] = options.metadata.title
            }
            if !options.metadata.author.isEmpty {
                attributes[PDFDocumentAttribute.authorAttribute] = options.metadata.author
            }
            if !options.metadata.subject.isEmpty {
                attributes[PDFDocumentAttribute.subjectAttribute] = options.metadata.subject
            }
            document.documentAttributes = attributes
        }

        let compressHigh = options.compress == .high
        let flatten = options.flattenAnnotations
        let userPassword = options.userPassword
        let ownerPassword = options.ownerPassword.isEmpty ? options.userPassword : options.ownerPassword
        let attributes = document.documentAttributes
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        guard let payload = document.dataRepresentation() else {
            throw FolioError.writeFailed
        }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let detached = PDFDocument(data: payload) else {
                    cont.resume(throwing: FolioError.writeFailed)
                    return
                }
                detached.documentAttributes = attributes
                var writeOptions: [PDFDocumentWriteOption: Any] = [:]
                if compressHigh {
                    writeOptions[.optimizeImagesForScreenOption] = true
                }
                if flatten {
                    writeOptions[.burnInAnnotationsOption] = true
                }
                if applyOCROption {
                    writeOptions[.saveTextFromOCROption] = true
                }
                if !userPassword.isEmpty {
                    writeOptions[.userPasswordOption] = userPassword
                    writeOptions[.ownerPasswordOption] = ownerPassword
                }
                if detached.write(to: url, withOptions: writeOptions) {
                    cont.resume()
                } else {
                    cont.resume(throwing: FolioError.writeFailed)
                }
            }
        }
    }

    static func fileSize(at url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        if let size = values?.fileSize {
            return Int64(size)
        }
        return 0
    }

    static func acceptedUTTypes() -> [String] {
        ["com.adobe.pdf", "public.png", "public.jpeg", "public.tiff", "public.heic", "org.webmproject.webp", "public.image"]
    }
}

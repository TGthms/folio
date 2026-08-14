import Foundation

enum Tool: String, CaseIterable, Identifiable, Sendable {
    case pages
    case merge
    case split
    case compress
    case watermark
    case pageNumbers
    case imagesToPDF
    case pdfToImages
    case extractText
    case ocr
    case protect
    case unlock
    case redact

    var id: String { rawValue }

    var group: ToolGroup {
        switch self {
        case .pages, .merge, .split: return .organize
        case .compress: return .reduce
        case .watermark, .pageNumbers: return .stamp
        case .imagesToPDF, .pdfToImages, .extractText, .ocr: return .convert
        case .protect, .unlock, .redact: return .secure
        }
    }

    var symbol: String {
        switch self {
        case .pages: return "rectangle.on.rectangle.angled"
        case .merge: return "square.stack"
        case .split: return "scissors"
        case .compress: return "arrow.down.forward.and.arrow.up.backward"
        case .watermark: return "drop"
        case .pageNumbers: return "number"
        case .imagesToPDF: return "photo.on.rectangle"
        case .pdfToImages: return "photo.stack"
        case .extractText: return "doc.text"
        case .ocr: return "text.viewfinder"
        case .protect: return "lock"
        case .unlock: return "lock.open"
        case .redact: return "eye.slash"
        }
    }

    var titleKey: String { "tool.\(rawValue)" }

    var suffixKey: String {
        switch self {
        case .merge, .pages: return "suffix.merged"
        case .split: return "suffix.part"
        case .compress: return "suffix.compressed"
        case .watermark, .pageNumbers: return "suffix.stamped"
        case .protect: return "suffix.locked"
        case .unlock: return "suffix.unlocked"
        case .ocr: return "suffix.searchable"
        case .redact: return "suffix.redacted"
        case .imagesToPDF: return "suffix.merged"
        case .pdfToImages: return "suffix.page"
        case .extractText: return "suffix.text"
        }
    }

    var defaultExtension: String {
        switch self {
        case .extractText: return "txt"
        case .pdfToImages: return "png"
        default: return "pdf"
        }
    }
}

enum ToolGroup: String, CaseIterable, Identifiable, Sendable {
    case organize
    case reduce
    case stamp
    case convert
    case secure

    var id: String { rawValue }
    var titleKey: String { "group.\(rawValue)" }

    var tools: [Tool] {
        Tool.allCases.filter { $0.group == self }
    }
}

enum StageMode: String, Sendable {
    case pages
    case read
}

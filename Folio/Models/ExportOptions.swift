import Foundation
import CoreGraphics

enum CompressPreset: String, CaseIterable, Identifiable, Sendable {
    case high
    case medium
    case small

    var id: String { rawValue }
    var titleKey: String { "compress.\(rawValue)" }

    var dpi: CGFloat {
        switch self {
        case .small: return 100
        case .medium: return 150
        case .high: return 0
        }
    }

    var jpegQuality: CGFloat {
        switch self {
        case .small: return 0.5
        case .medium: return 0.7
        case .high: return 1
        }
    }
}

enum WatermarkPosition: String, CaseIterable, Identifiable, Sendable {
    case center, tile, topLeft, topRight, bottomLeft, bottomRight

    var id: String { rawValue }
    var titleKey: String { "watermark.position.\(rawValue)" }
}

enum PageNumberFormat: String, CaseIterable, Identifiable, Sendable {
    case number
    case of
    case page

    var id: String { rawValue }
    var titleKey: String { "pageNumbers.format.\(rawValue)" }
}

enum PageNumberPosition: String, CaseIterable, Identifiable, Sendable {
    case headerLeft, headerCenter, headerRight
    case footerLeft, footerCenter, footerRight

    var id: String { rawValue }
    var titleKey: String { "pageNumbers.position.\(rawValue)" }
}

enum ImagePageSize: String, CaseIterable, Identifiable, Sendable {
    case imageSize
    case letter
    case a4

    var id: String { rawValue }
    var titleKey: String { "images.pageSize.\(rawValue)" }

    var size: CGSize? {
        switch self {
        case .imageSize: return nil
        case .letter: return CGSize(width: 612, height: 792)
        case .a4: return CGSize(width: 595.28, height: 841.89)
        }
    }
}

enum ImageExportFormat: String, CaseIterable, Identifiable, Sendable {
    case png
    case jpeg

    var id: String { rawValue }
    var fileExtension: String { rawValue == "jpeg" ? "jpg" : rawValue }
}

enum RedactFill: String, CaseIterable, Identifiable, Sendable {
    case black
    case white

    var id: String { rawValue }
    var titleKey: String { "redact.fill.\(rawValue)" }
}

enum SplitMode: String, CaseIterable, Identifiable, Sendable {
    case selected
    case ranges
    case every
    case eachPage

    var id: String { rawValue }
    var titleKey: String { "split.\(rawValue)" }
}

struct WatermarkOptions: Equatable, Sendable {
    var text: String = "CONFIDENTIAL"
    var imageURL: URL?
    var opacity: Double = 0.18
    var rotation: Double = -32
    var position: WatermarkPosition = .center
}

struct PageNumberOptions: Equatable, Sendable {
    var format: PageNumberFormat = .of
    var position: PageNumberPosition = .footerCenter
    var startAt: Int = 1
    var skipFirst: Bool = false
}

struct MetadataOptions: Equatable, Sendable {
    var title: String = ""
    var author: String = ""
    var subject: String = ""
}

struct ExportOptions: Equatable, Sendable {
    var compress: CompressPreset = .medium
    var grayscale: Bool = false
    var flattenAnnotations: Bool = false
    var watermark = WatermarkOptions()
    var pageNumbers = PageNumberOptions()
    var userPassword: String = ""
    var userPasswordConfirm: String = ""
    var ownerPassword: String = ""
    var ocr: Bool = true
    var metadata = MetadataOptions()
    var imagePageSize: ImagePageSize = .letter
    var imageFormat: ImageExportFormat = .png
    var imageDPI: Int = 144
    var redactFill: RedactFill = .black
    var replaceOriginal: Bool = false
    var splitMode: SplitMode = .selected
    var splitRanges: String = ""
    var splitEvery: Int = 1
    var oneFilePerRange: Bool = true
}

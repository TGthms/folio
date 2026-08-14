import Foundation
import PDFKit

enum TextService {
    static func extract(from pages: [PDFPage]) -> String {
        var parts: [String] = []
        for (index, page) in pages.enumerated() {
            let text = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !text.isEmpty {
                parts.append(text)
            } else {
                parts.append("")
            }
            if index + 1 < pages.count {
                parts.append("\n\n")
            }
        }
        return parts.joined()
    }

    static func pageHasText(_ page: PDFPage) -> Bool {
        let text = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !text.isEmpty
    }

    static func isNearlyBlank(_ page: PDFPage) -> Bool {
        if pageHasText(page) { return false }
        let thumb = page.thumbnail(of: CGSize(width: 48, height: 48), for: .mediaBox)
        guard let cg = thumb.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return true }
        return meanLuminance(cg) > 0.96
    }

    static func meanLuminance(_ image: CGImage) -> CGFloat {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return 1 }
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let data = context.data else { return 1 }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        var total: CGFloat = 0
        let count = width * height
        for i in 0..<count {
            let o = i * 4
            let r = CGFloat(pointer[o])
            let g = CGFloat(pointer[o + 1])
            let b = CGFloat(pointer[o + 2])
            total += (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
        }
        return total / CGFloat(count)
    }
}

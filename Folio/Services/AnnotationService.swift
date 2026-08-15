import AppKit
import PDFKit

enum AnnotationService {
    static let owner = "folio"

    static func fingerprint(pages: [PageRef]) -> String {
        pages.map { page in
            let marks = page.marks.map(\.id.uuidString).joined(separator: ",")
            return "\(page.id.uuidString):\(marks):\(page.cropRect?.debugDescription ?? "-")"
        }.joined(separator: "|")
    }

    static func sync(document: PDFDocument, pages: [PageRef]) {
        for (index, ref) in pages.enumerated() {
            guard let page = document.page(at: index) else { continue }
            sync(page: page, marks: ref.marks, crop: ref.cropRect)
        }
    }

    static func sync(page: PDFPage, marks: [PageMark], crop: CGRect?) {
        for annotation in page.annotations where annotation.userName == owner {
            page.removeAnnotation(annotation)
        }
        for mark in marks {
            page.addAnnotation(make(mark))
        }
        let media = page.bounds(for: .mediaBox)
        page.setBounds(crop?.intersection(media) ?? media, for: .cropBox)
    }

    static func make(_ mark: PageMark) -> PDFAnnotation {
        let annotation: PDFAnnotation
        switch mark.kind {
        case .highlight:
            annotation = PDFAnnotation(bounds: mark.rect, forType: .highlight, withProperties: nil)
            annotation.color = NSColor.systemYellow.withAlphaComponent(0.45)
            annotation.quadrilateralPoints = quadPoints(in: mark.rect)
        case .underline:
            annotation = PDFAnnotation(bounds: mark.rect, forType: .underline, withProperties: nil)
            annotation.color = NSColor.systemYellow
            annotation.quadrilateralPoints = quadPoints(in: mark.rect)
        case .textBox:
            annotation = PDFAnnotation(bounds: mark.rect, forType: .freeText, withProperties: nil)
            annotation.contents = mark.text
            annotation.font = NSFont.systemFont(ofSize: max(9, min(14, mark.rect.height * 0.45)))
            annotation.fontColor = .black
            annotation.color = .white
        case .stroke:
            annotation = PDFAnnotation(bounds: mark.rect, forType: .ink, withProperties: nil)
            annotation.color = .systemRed
            annotation.border = PDFBorder()
            annotation.border?.lineWidth = 2
            let path = NSBezierPath()
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            for (index, point) in mark.points.enumerated() {
                let local = CGPoint(x: point.x - mark.rect.minX, y: point.y - mark.rect.minY)
                if index == 0 { path.move(to: local) } else { path.line(to: local) }
            }
            annotation.add(path)
        }
        annotation.userName = owner
        annotation.setValue(mark.id.uuidString, forAnnotationKey: .name)
        return annotation
    }

    static func markID(from annotation: PDFAnnotation) -> UUID? {
        guard annotation.userName == owner else { return nil }
        if let name = annotation.value(forAnnotationKey: .name) as? String {
            return UUID(uuidString: name)
        }
        return nil
    }

    static func marks(from selection: PDFSelection, kind: PageMarkKind) -> [(page: PDFPage, mark: PageMark)] {
        var result: [(PDFPage, PageMark)] = []
        let lines = selection.selectionsByLine()
        let pieces = lines.isEmpty ? [selection] : lines
        for piece in pieces {
            for page in piece.pages {
                let rect = piece.bounds(for: page)
                guard !rect.isNull, rect.width > 1, rect.height > 1 else { continue }
                result.append((page, PageMark(kind: kind, rect: rect)))
            }
        }
        return result
    }

    private static func quadPoints(in rect: CGRect) -> [NSValue] {
        [
            NSValue(point: CGPoint(x: 0, y: rect.height)),
            NSValue(point: CGPoint(x: rect.width, y: rect.height)),
            NSValue(point: CGPoint(x: 0, y: 0)),
            NSValue(point: CGPoint(x: rect.width, y: 0)),
        ]
    }
}

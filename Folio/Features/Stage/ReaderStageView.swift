import AppKit
import PDFKit
import SwiftUI

struct ReaderStage: NSViewRepresentable {
    var document: PDFDocument?
    var focusedIndex: Int
    var tool: Tool
    var editMark: EditMarkKind
    var pages: [PageRef]
    var onVisiblePage: (Int) -> Void
    var onMark: (PageMark, UUID) -> Void
    var onRedaction: (CGRect, UUID) -> Void
    var onCrop: (CGRect, UUID) -> Void
    var onAskText: () -> String?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> ReaderHostView {
        let host = ReaderHostView()
        context.coordinator.install(on: host)
        return host
    }

    func updateNSView(_ host: ReaderHostView, context: Context) {
        context.coordinator.onVisiblePage = onVisiblePage
        host.overlay.tool = tool
        host.overlay.editMark = editMark
        host.overlay.pages = pages
        host.overlay.onMark = onMark
        host.overlay.onRedaction = onRedaction
        host.overlay.onCrop = onCrop
        host.overlay.onAskText = onAskText
        host.overlay.window?.invalidateCursorRects(for: host.overlay)

        if host.pdfView.document !== document {
            context.coordinator.ignorePageChange = true
            host.pdfView.autoScales = true
            host.pdfView.document = document
            context.coordinator.resetFocus()
            context.coordinator.observeDocumentScroll(host.pdfView, overlay: host.overlay)
            context.coordinator.ignorePageChange = false
            DispatchQueue.main.async { [weak host] in
                host?.pdfView.autoScales = false
            }
        }
        context.coordinator.applyFocus(focusedIndex, in: host.pdfView)
        host.overlay.needsDisplay = true
    }

    final class Coordinator: NSObject, PDFViewDelegate, @unchecked Sendable {
        var onVisiblePage: (Int) -> Void = { _ in }
        var ignorePageChange = false
        var lastVisible = -1
        var lastApplied = -1
        private var pageObserver: NSObjectProtocol?
        private var scaleObserver: NSObjectProtocol?
        private var scrollObserver: NSObjectProtocol?

        func resetFocus() {
            lastVisible = -1
            lastApplied = -1
        }

        func install(on host: ReaderHostView) {
            host.pdfView.delegate = self
            pageObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewPageChanged,
                object: host.pdfView,
                queue: .main
            ) { [weak self, weak host] _ in
                guard let self, let host, !self.ignorePageChange else { return }
                self.noteVisiblePage(in: host.pdfView)
                host.overlay.needsDisplay = true
            }
            scaleObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewScaleChanged,
                object: host.pdfView,
                queue: .main
            ) { [weak host] _ in
                host?.overlay.needsDisplay = true
            }
            observeDocumentScroll(host.pdfView, overlay: host.overlay)
        }

        func observeDocumentScroll(_ pdfView: PDFView, overlay: ReaderOverlayView) {
            if let scrollObserver {
                NotificationCenter.default.removeObserver(scrollObserver)
            }
            pdfView.documentView?.postsBoundsChangedNotifications = true
            scrollObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: pdfView.documentView,
                queue: .main
            ) { [weak overlay] _ in
                overlay?.needsDisplay = true
            }
        }

        func applyFocus(_ focusedIndex: Int, in pdfView: PDFView) {
            guard ReaderFocusPolicy.shouldJump(
                to: focusedIndex,
                lastVisible: lastVisible,
                lastApplied: lastApplied
            ) else {
                return
            }
            guard let document = pdfView.document,
                  focusedIndex < document.pageCount,
                  let page = document.page(at: focusedIndex)
            else { return }
            ignorePageChange = true
            pdfView.go(to: page)
            ignorePageChange = false
            lastApplied = focusedIndex
            lastVisible = focusedIndex
        }

        func noteVisiblePage(in pdfView: PDFView) {
            guard let page = pdfView.currentPage, let document = pdfView.document else { return }
            let index = document.index(for: page)
            guard index != NSNotFound else { return }
            lastVisible = index
            lastApplied = index
            onVisiblePage(index)
        }

        deinit {
            if let pageObserver { NotificationCenter.default.removeObserver(pageObserver) }
            if let scaleObserver { NotificationCenter.default.removeObserver(scaleObserver) }
            if let scrollObserver { NotificationCenter.default.removeObserver(scrollObserver) }
        }
    }
}

final class ReaderHostView: NSView {
    let pdfView = PDFView()
    let overlay = ReaderOverlayView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        overlay.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.minScaleFactor = 0.25
        pdfView.maxScaleFactor = 4
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        overlay.pdfView = pdfView
        addSubview(pdfView)
        addSubview(overlay)
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: pdfView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ReaderOverlayView: NSView {
    weak var pdfView: PDFView?
    var tool: Tool = .pages {
        didSet { if tool != oldValue { window?.invalidateCursorRects(for: self) } }
    }
    var editMark: EditMarkKind = .highlight
    var pages: [PageRef] = []
    var onMark: ((PageMark, UUID) -> Void)?
    var onRedaction: ((CGRect, UUID) -> Void)?
    var onCrop: ((CGRect, UUID) -> Void)?
    var onAskText: (() -> String?)?

    private var dragStart: CGPoint?
    private var dragCurrent: CGPoint?
    private var strokeViewPoints: [CGPoint] = []

    override var isOpaque: Bool { false }
    override var acceptsFirstResponder: Bool { capturing }
    override var isFlipped: Bool { pdfView?.isFlipped ?? false }

    private var capturing: Bool {
        tool == .edit || tool == .redact
    }

    override func resetCursorRects() {
        if capturing {
            addCursorRect(bounds, cursor: .crosshair)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        capturing ? super.hitTest(point) : nil
    }

    override func scrollWheel(with event: NSEvent) {
        pdfView?.scrollWheel(with: event)
    }

    override func magnify(with event: NSEvent) {
        pdfView?.magnify(with: event)
    }

    override func smartMagnify(with event: NSEvent) {
        pdfView?.smartMagnify(with: event)
    }

    override func beginGesture(with event: NSEvent) {
        pdfView?.beginGesture(with: event)
    }

    override func endGesture(with event: NSEvent) {
        pdfView?.endGesture(with: event)
    }

    override func rotate(with event: NSEvent) {
        pdfView?.rotate(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        guard capturing else {
            pdfView?.mouseDown(with: event)
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        dragStart = point
        dragCurrent = point
        strokeViewPoints = [point]
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard capturing, dragStart != nil else {
            pdfView?.mouseDragged(with: event)
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        dragCurrent = point
        if tool == .edit, editMark == .draw {
            strokeViewPoints.append(point)
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard capturing else {
            pdfView?.mouseUp(with: event)
            return
        }
        let end = convert(event.locationInWindow, from: nil)
        commitGesture(end: end)
        dragStart = nil
        dragCurrent = nil
        strokeViewPoints = []
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let pdfView, let document = pdfView.document else { return }
        for (index, page) in pages.enumerated() {
            guard index < document.pageCount, let pdfPage = document.page(at: index) else { continue }
            if let crop = page.cropRect {
                drawCropVeil(crop, page: pdfPage, pdfView: pdfView)
            }
            for redaction in page.redactions {
                let rect = pdfView.convert(redaction.rect, from: pdfPage)
                FolioOverlayStyle.vermilion.withAlphaComponent(0.28).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2).fill()
            }
            for mark in page.marks {
                drawCommitted(mark, page: pdfPage, pdfView: pdfView)
            }
        }
        drawLivePreview()
    }

    private func commitGesture(end: CGPoint) {
        guard let start = dragStart, let pdfView else { return }
        if tool == .edit, editMark == .draw {
            commitStroke(in: pdfView)
            return
        }
        let viewRect = EditGestureMath.rect(from: start, to: end)
        guard EditGestureMath.isCommitable(viewRect) else { return }
        guard let target = targetPage(at: start, in: pdfView) else { return }
        let pageRect = pdfView.convert(viewRect, to: target.page)
        if tool == .redact {
            onRedaction?(pageRect, target.id)
            return
        }
        if editMark == .crop {
            onCrop?(pageRect, target.id)
            return
        }
        var text = ""
        if editMark == .textBox {
            guard let entered = onAskText?() else { return }
            text = entered
        }
        guard let kind = editMark.markKind else { return }
        onMark?(PageMark(kind: kind, rect: pageRect, text: text), target.id)
    }

    private func commitStroke(in pdfView: PDFView) {
        guard strokeViewPoints.count > 1, let first = strokeViewPoints.first else { return }
        guard let target = targetPage(at: first, in: pdfView) else { return }
        let pdfPoints = strokeViewPoints.map { pdfView.convert($0, to: target.page) }
        guard pdfPoints.count > 1 else { return }
        onMark?(PageMark(kind: .stroke, rect: EditGestureMath.strokeBounds(pdfPoints), points: pdfPoints), target.id)
    }

    private func targetPage(at viewPoint: CGPoint, in pdfView: PDFView) -> (page: PDFPage, id: UUID)? {
        let pdfPoint = pdfView.convert(viewPoint, from: self)
        guard let page = pdfView.page(for: pdfPoint, nearest: true),
              let document = pdfView.document
        else { return nil }
        let index = document.index(for: page)
        guard let id = ReaderPageIndex.id(at: index, in: pages.map(\.id)) else { return nil }
        return (page, id)
    }

    private func drawCropVeil(_ crop: CGRect, page: PDFPage, pdfView: PDFView) {
        let keep = pdfView.convert(crop, from: page)
        let path = NSBezierPath(rect: bounds)
        path.appendRect(keep)
        path.windingRule = .evenOdd
        NSColor.black.withAlphaComponent(0.28).setFill()
        path.fill()
        FolioOverlayStyle.vermilion.setStroke()
        path.lineWidth = 1
        NSBezierPath(rect: keep).stroke()
    }

    private func drawCommitted(_ mark: PageMark, page: PDFPage, pdfView: PDFView) {
        switch mark.kind {
        case .highlight:
            let rect = pdfView.convert(mark.rect, from: page)
            NSColor.systemYellow.withAlphaComponent(0.28).setFill()
            NSBezierPath(rect: rect).fill()
        case .underline:
            let rect = pdfView.convert(mark.rect, from: page)
            NSColor.systemYellow.setStroke()
            let path = NSBezierPath()
            path.lineWidth = 2
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
            path.line(to: CGPoint(x: rect.maxX, y: rect.minY + 1))
            path.stroke()
        case .textBox:
            let rect = pdfView.convert(mark.rect, from: page)
            NSColor.white.withAlphaComponent(0.9).setFill()
            NSColor.black.withAlphaComponent(0.25).setStroke()
            let box = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
            box.lineWidth = 0.6
            box.fill()
            box.stroke()
            if !mark.text.isEmpty {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: max(8, min(14, rect.height * 0.45))),
                    .foregroundColor: NSColor.black,
                ]
                (mark.text as NSString).draw(in: rect.insetBy(dx: 4, dy: 3), withAttributes: attrs)
            }
        case .stroke:
            let path = NSBezierPath()
            path.lineWidth = 2
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            for (index, point) in mark.points.enumerated() {
                let viewPoint = pdfView.convert(point, from: page)
                if index == 0 { path.move(to: viewPoint) } else { path.line(to: viewPoint) }
            }
            NSColor.systemRed.setStroke()
            path.stroke()
        }
    }

    private func drawLivePreview() {
        guard capturing, let start = dragStart, let current = dragCurrent else { return }
        if tool == .edit, editMark == .draw, strokeViewPoints.count > 1 {
            let path = NSBezierPath()
            path.lineWidth = 2
            path.lineCapStyle = .round
            path.move(to: strokeViewPoints[0])
            for point in strokeViewPoints.dropFirst() {
                path.line(to: point)
            }
            NSColor.systemRed.withAlphaComponent(0.9).setStroke()
            path.stroke()
            return
        }
        let rect = EditGestureMath.rect(from: start, to: current)
        if tool == .redact {
            FolioOverlayStyle.vermilion.withAlphaComponent(0.28).setFill()
            NSBezierPath(rect: rect).fill()
            return
        }
        switch editMark {
        case .crop:
            FolioOverlayStyle.vermilion.withAlphaComponent(0.08).setFill()
            FolioOverlayStyle.vermilion.setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 1.5
            path.fill()
            path.stroke()
        case .underline:
            NSColor.systemYellow.setStroke()
            let path = NSBezierPath()
            path.lineWidth = 2
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
            path.line(to: CGPoint(x: rect.maxX, y: rect.minY + 1))
            path.stroke()
        case .textBox:
            NSColor.white.withAlphaComponent(0.85).setFill()
            NSColor.black.withAlphaComponent(0.28).setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 0.6
            path.fill()
            path.stroke()
        default:
            NSColor.systemYellow.withAlphaComponent(0.25).setFill()
            NSBezierPath(rect: rect).fill()
        }
    }
}

private enum FolioOverlayStyle {
    static let vermilion = NSColor(red: 0.761, green: 0.231, blue: 0.133, alpha: 1)
}

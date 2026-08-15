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
    var onReplaceMark: (PageMark) -> Void
    var onRedaction: (CGRect, UUID) -> Void
    var onCrop: (CGRect, UUID) -> Void
    var onSelectMark: (UUID?) -> Void
    var onRemoveMark: (UUID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> FolioPDFHost {
        let host = FolioPDFHost()
        host.pdfView.delegate = context.coordinator
        context.coordinator.install(on: host.pdfView)
        host.setContentHuggingPriority(.defaultLow, for: .horizontal)
        host.setContentHuggingPriority(.defaultLow, for: .vertical)
        host.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        host.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return host
    }

    func updateNSView(_ host: FolioPDFHost, context: Context) {
        context.coordinator.onVisiblePage = onVisiblePage
        let view = host.pdfView
        view.tool = tool
        view.editMark = editMark
        view.pages = pages
        view.onMark = onMark
        view.onReplaceMark = onReplaceMark
        view.onRedaction = onRedaction
        view.onCrop = onCrop
        view.onSelectMark = onSelectMark
        view.onRemoveMark = onRemoveMark

        if view.document !== document {
            host.finishTextEdit(commit: false)
            context.coordinator.ignorePageChange = true
            view.document = document
            view.layoutDocumentView()
            context.coordinator.resetFocus()
            context.coordinator.ignorePageChange = false
            context.coordinator.lastAnnotationSync = ""
        }
        if let document = view.document, !view.isInteracting {
            let fingerprint = AnnotationService.fingerprint(pages: pages)
            if fingerprint != context.coordinator.lastAnnotationSync {
                AnnotationService.sync(document: document, pages: pages)
                context.coordinator.lastAnnotationSync = fingerprint
            }
        }
        context.coordinator.applyFocus(focusedIndex, in: view)
        view.window?.invalidateCursorRects(for: view)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: FolioPDFHost, context: Context) -> CGSize {
        proposal.replacingUnspecifiedDimensions(by: CGSize(width: 720, height: 540))
    }

    final class Coordinator: NSObject, PDFViewDelegate, @unchecked Sendable {
        var onVisiblePage: (Int) -> Void = { _ in }
        var ignorePageChange = false
        var lastVisible = -1
        var lastApplied = -1
        var lastAnnotationSync = ""
        private var pageObserver: NSObjectProtocol?
        private var annotationObserver: NSObjectProtocol?

        func resetFocus() {
            lastVisible = -1
            lastApplied = -1
        }

        func install(on view: FolioPDFView) {
            pageObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewPageChanged,
                object: view,
                queue: .main
            ) { [weak self, weak view] _ in
                guard let self, let view, !self.ignorePageChange else { return }
                self.noteVisiblePage(in: view)
            }
            annotationObserver = NotificationCenter.default.addObserver(
                forName: .PDFViewAnnotationHit,
                object: view,
                queue: .main
            ) { [weak view] notification in
                let annotation = notification.userInfo?["PDFAnnotationHit"] as? PDFAnnotation
                view?.onSelectMark?(annotation.flatMap(AnnotationService.markID(from:)))
            }
        }

        func applyFocus(_ focusedIndex: Int, in pdfView: PDFView) {
            guard ReaderFocusPolicy.shouldJump(
                to: focusedIndex,
                lastVisible: lastVisible,
                lastApplied: lastApplied
            ) else { return }
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
            if let annotationObserver { NotificationCenter.default.removeObserver(annotationObserver) }
        }
    }
}

/// Fills the SwiftUI proposal. PDFView then scrolls inside that viewport — never the document height.
final class FolioPDFHost: NSView, NSTextFieldDelegate {
    let pdfView = FolioPDFView()
    let rubber = RubberOverlay()
    private var editor: NSTextField?
    private var editorPage: PDFPage?
    private var editorPageID: UUID?
    private var editorPageRect: CGRect = .zero
    private var editorMark: PageMark?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        rubber.translatesAutoresizingMaskIntoConstraints = false
        pdfView.host = self
        pdfView.autoScales = true
        pdfView.minScaleFactor = 0.25
        pdfView.maxScaleFactor = 8
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        pdfView.displaysPageBreaks = true
        pdfView.interpolationQuality = .high
        addSubview(pdfView)
        addSubview(rubber)
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rubber.topAnchor.constraint(equalTo: topAnchor),
            rubber.leadingAnchor.constraint(equalTo: leadingAnchor),
            rubber.trailingAnchor.constraint(equalTo: trailingAnchor),
            rubber.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(repositionEditorNote),
            name: .PDFViewScaleChanged,
            object: pdfView
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(repositionEditorNote),
            name: .PDFViewPageChanged,
            object: pdfView
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override var acceptsFirstResponder: Bool { true }

    override func layout() {
        super.layout()
        repositionEditor()
    }

    func beginTextEdit(pageRect: CGRect, page: PDFPage, pageID: UUID, existing: PageMark?) {
        finishTextEdit(commit: true)
        editorPage = page
        editorPageID = pageID
        editorPageRect = pageRect
        editorMark = existing
        pdfView.isInteracting = true
        let field = NSTextField(string: existing?.text ?? "")
        field.placeholderString = L10n.t("edit.textPrompt")
        field.font = NSFont.systemFont(ofSize: max(11, min(18, pageRect.height * pdfView.scaleFactor * 0.5)))
        field.focusRingType = .exterior
        field.isBezeled = true
        field.bezelStyle = .squareBezel
        field.drawsBackground = true
        field.backgroundColor = .white
        field.textColor = .black
        field.delegate = self
        addSubview(field, positioned: .above, relativeTo: rubber)
        editor = field
        repositionEditor()
        window?.makeFirstResponder(field)
    }

    var isEditingText: Bool { editor != nil }

    func finishTextEdit(commit: Bool) {
        guard let field = editor else { return }
        let text = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let pageID = editorPageID
        let pageRect = editorPageRect
        let existing = editorMark
        field.delegate = nil
        field.removeFromSuperview()
        editor = nil
        editorPage = nil
        editorPageID = nil
        editorMark = nil
        pdfView.isInteracting = false
        window?.makeFirstResponder(pdfView)
        guard commit, let pageID else { return }
        if let existing {
            if text.isEmpty {
                pdfView.onRemoveMark?(existing.id)
            } else if text != existing.text {
                var next = existing
                next.text = text
                pdfView.onReplaceMark?(next)
            }
            return
        }
        guard !text.isEmpty else { return }
        pdfView.onMark?(PageMark(kind: .textBox, rect: pageRect, text: text), pageID)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        finishTextEdit(commit: true)
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            finishTextEdit(commit: false)
            return true
        }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            finishTextEdit(commit: true)
            return true
        }
        return false
    }

    @objc private func repositionEditorNote() {
        repositionEditor()
    }

    private func repositionEditor() {
        guard let field = editor, let page = editorPage else { return }
        var rect = convert(pdfView.convert(editorPageRect, from: page), from: pdfView)
        rect.size.width = max(120, rect.width)
        rect.size.height = max(22, rect.height)
        field.frame = rect
    }
}

/// Draws the rubber band. `hitTest` is always nil so trackpad scroll reaches PDFView.
final class RubberOverlay: NSView {
    var path: CGPath? {
        didSet { needsDisplay = true }
    }
    var fillColor: NSColor = .clear
    var strokeColor: NSColor = .systemYellow
    var lineWidth: CGFloat = 1

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override var isOpaque: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let path else { return }
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.saveGState()
        ctx?.addPath(path)
        if fillColor.alphaComponent > 0 {
            fillColor.setFill()
            ctx?.fillPath()
            ctx?.addPath(path)
        }
        strokeColor.setStroke()
        ctx?.setLineWidth(lineWidth)
        ctx?.setLineCap(.round)
        ctx?.setLineJoin(.round)
        ctx?.strokePath()
        ctx?.restoreGState()
    }
}

final class FolioPDFView: PDFView {
    weak var host: FolioPDFHost?
    var tool: Tool = .pages {
        didSet { if tool != oldValue { window?.invalidateCursorRects(for: self) } }
    }
    var editMark: EditMarkKind = .select {
        didSet { if editMark != oldValue { window?.invalidateCursorRects(for: self) } }
    }
    var pages: [PageRef] = []
    var onMark: ((PageMark, UUID) -> Void)?
    var onReplaceMark: ((PageMark) -> Void)?
    var onRedaction: ((CGRect, UUID) -> Void)?
    var onCrop: ((CGRect, UUID) -> Void)?
    var onSelectMark: ((UUID?) -> Void)?
    var onRemoveMark: ((UUID) -> Void)?
    var isInteracting = false

    private var dragStart: NSPoint?
    private var strokePoints: [NSPoint] = []
    private var moving: MovingMark?

    private struct MovingMark {
        var mark: PageMark
        var annotation: PDFAnnotation
        var startPagePoint: CGPoint
        var originalRect: CGRect
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override var intrinsicContentSize: CGSize {
        CGSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override func resetCursorRects() {
        switch (tool, editMark) {
        case (.edit, .highlight), (.edit, .underline):
            addCursorRect(bounds, cursor: .iBeam)
        case (.edit, .textBox), (.edit, .draw), (.edit, .crop), (.redact, _):
            addCursorRect(bounds, cursor: .crosshair)
        default:
            super.resetCursorRects()
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        if tool == .edit, editMark == .select, let hit = folioHit(at: point) {
            if event.clickCount == 2, hit.mark.kind == .textBox {
                host?.beginTextEdit(pageRect: hit.mark.rect, page: hit.page, pageID: hit.pageID, existing: hit.mark)
                onSelectMark?(hit.mark.id)
                return
            }
            moving = MovingMark(
                mark: hit.mark,
                annotation: hit.annotation,
                startPagePoint: convert(point, to: hit.page),
                originalRect: hit.annotation.bounds
            )
            isInteracting = true
            onSelectMark?(hit.mark.id)
            return
        }
        dragStart = point
        strokePoints = [point]
        if EditInteraction.usesNativePointer(tool, mark: editMark) {
            if event.clickCount == 1 { onSelectMark?(nil) }
            super.mouseDown(with: event)
            return
        }
        isInteracting = true
        updateRubber(to: point)
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if var moving {
            guard let page = moving.annotation.page else { return }
            let now = convert(point, to: page)
            let dx = now.x - moving.startPagePoint.x
            let dy = now.y - moving.startPagePoint.y
            moving.annotation.bounds = moving.originalRect.offsetBy(dx: dx, dy: dy)
            self.moving = moving
            return
        }
        if EditInteraction.usesNativePointer(tool, mark: editMark) {
            super.mouseDragged(with: event)
            return
        }
        if tool == .edit, editMark == .draw {
            strokePoints.append(point)
        }
        updateRubber(to: point)
    }

    override func mouseUp(with event: NSEvent) {
        let end = convert(event.locationInWindow, from: nil)
        defer {
            dragStart = nil
            strokePoints = []
            moving = nil
            if host?.isEditingText != true {
                isInteracting = false
            }
            clearRubber()
        }
        if let moving {
            commitMove(moving, end: end)
            return
        }
        if EditInteraction.usesNativePointer(tool, mark: editMark) {
            super.mouseUp(with: event)
            _ = applyTextSelectionMarks()
            return
        }
        commitAreaIfNeeded(end: end)
    }

    private func applyTextSelectionMarks() -> Bool {
        guard tool == .edit,
              let kind = editMark.markKind,
              kind == .highlight || kind == .underline,
              let selection = currentSelection
        else { return false }
        let pieces = AnnotationService.marks(from: selection, kind: kind)
        guard !pieces.isEmpty else { return false }
        for piece in pieces {
            let index = document?.index(for: piece.page) ?? NSNotFound
            guard let id = ReaderPageIndex.id(at: index, in: pages.map(\.id)) else { continue }
            onMark?(piece.mark, id)
        }
        clearSelection()
        return true
    }

    private func commitAreaIfNeeded(end: NSPoint) {
        guard let start = dragStart else { return }
        if tool == .edit, editMark == .draw {
            commitStroke()
            return
        }
        if tool == .edit, editMark == .textBox {
            commitTextBox(from: start, to: end)
            return
        }
        guard EditInteraction.commitsDragRect(tool, mark: editMark) else { return }
        let viewRect = EditGestureMath.rect(from: start, to: end)
        guard EditGestureMath.isCommitable(viewRect),
              let target = targetPage(at: start)
        else { return }
        let pageRect = convert(viewRect, to: target.page)
        if tool == .redact {
            onRedaction?(pageRect, target.id)
            return
        }
        if editMark == .crop {
            onCrop?(pageRect, target.id)
        }
    }

    private func commitTextBox(from start: NSPoint, to end: NSPoint) {
        guard let target = targetPage(at: start) else { return }
        var viewRect = EditGestureMath.rect(from: start, to: end)
        if !EditGestureMath.isCommitable(viewRect) {
            viewRect = CGRect(x: end.x, y: end.y - 22, width: 168, height: 24)
        }
        let pageRect = convert(viewRect, to: target.page)
        host?.beginTextEdit(pageRect: pageRect, page: target.page, pageID: target.id, existing: nil)
    }

    private func commitStroke() {
        guard strokePoints.count > 1, let first = strokePoints.first, let target = targetPage(at: first) else { return }
        let pdfPoints = strokePoints.map { convert($0, to: target.page) }
        onMark?(
            PageMark(kind: .stroke, rect: EditGestureMath.strokeBounds(pdfPoints), points: pdfPoints),
            target.id
        )
    }

    private func commitMove(_ moving: MovingMark, end: NSPoint) {
        guard let page = moving.annotation.page else { return }
        let now = convert(end, to: page)
        let dx = now.x - moving.startPagePoint.x
        let dy = now.y - moving.startPagePoint.y
        guard hypot(dx, dy) > 2 else { return }
        var mark = moving.mark
        mark.rect = moving.originalRect.offsetBy(dx: dx, dy: dy)
        if !mark.points.isEmpty {
            mark.points = mark.points.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
        }
        onReplaceMark?(mark)
    }

    private func folioHit(at viewPoint: NSPoint) -> (mark: PageMark, annotation: PDFAnnotation, page: PDFPage, pageID: UUID)? {
        guard let page = page(for: viewPoint, nearest: true), let document else { return nil }
        let index = document.index(for: page)
        guard let pageID = ReaderPageIndex.id(at: index, in: pages.map(\.id)) else { return nil }
        let pagePoint = convert(viewPoint, to: page)
        guard let annotation = page.annotation(at: pagePoint),
              let id = AnnotationService.markID(from: annotation),
              let mark = pages.first(where: { $0.id == pageID })?.marks.first(where: { $0.id == id })
        else { return nil }
        return (mark, annotation, page, pageID)
    }

    private func targetPage(at viewPoint: NSPoint) -> (page: PDFPage, id: UUID)? {
        guard let page = page(for: viewPoint, nearest: true), let document else { return nil }
        let index = document.index(for: page)
        guard let id = ReaderPageIndex.id(at: index, in: pages.map(\.id)) else { return nil }
        return (page, id)
    }

    private func updateRubber(to current: NSPoint) {
        guard let start = dragStart, let overlay = host?.rubber else { return }
        if tool == .edit, editMark == .draw {
            let path = CGMutablePath()
            if let first = strokePoints.first {
                path.move(to: first)
                for point in strokePoints.dropFirst() { path.addLine(to: point) }
            }
            overlay.fillColor = .clear
            overlay.strokeColor = .systemRed
            overlay.lineWidth = 2
            overlay.path = path
            return
        }
        let rect = EditGestureMath.rect(from: start, to: current)
        if tool == .redact {
            overlay.fillColor = NSColor(red: 0.761, green: 0.231, blue: 0.133, alpha: 0.28)
            overlay.strokeColor = NSColor(red: 0.761, green: 0.231, blue: 0.133, alpha: 1)
        } else if editMark == .crop {
            overlay.fillColor = NSColor(red: 0.761, green: 0.231, blue: 0.133, alpha: 0.08)
            overlay.strokeColor = NSColor(red: 0.761, green: 0.231, blue: 0.133, alpha: 1)
        } else {
            overlay.fillColor = NSColor.white.withAlphaComponent(0.85)
            overlay.strokeColor = NSColor.black.withAlphaComponent(0.3)
        }
        overlay.lineWidth = 1
        overlay.path = CGPath(rect: rect, transform: nil)
    }

    private func clearRubber() {
        host?.rubber.path = nil
    }
}

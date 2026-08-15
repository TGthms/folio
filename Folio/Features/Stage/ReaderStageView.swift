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
    var onSelectMark: (UUID?) -> Void
    var onAskText: () -> String?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> FolioPDFView {
        let view = FolioPDFView()
        view.autoScales = true
        view.minScaleFactor = 0.25
        view.maxScaleFactor = 8
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        context.coordinator.install(on: view)
        return view
    }

    func updateNSView(_ view: FolioPDFView, context: Context) {
        context.coordinator.onVisiblePage = onVisiblePage
        view.tool = tool
        view.editMark = editMark
        view.pages = pages
        view.onMark = onMark
        view.onRedaction = onRedaction
        view.onCrop = onCrop
        view.onSelectMark = onSelectMark
        view.onAskText = onAskText

        if view.document !== document {
            context.coordinator.ignorePageChange = true
            view.document = document
            context.coordinator.resetFocus()
            context.coordinator.ignorePageChange = false
            context.coordinator.lastAnnotationSync = ""
        }
        if let document = view.document {
            let fingerprint = AnnotationService.fingerprint(pages: pages)
            if fingerprint != context.coordinator.lastAnnotationSync {
                AnnotationService.sync(document: document, pages: pages)
                context.coordinator.lastAnnotationSync = fingerprint
            }
        }
        context.coordinator.applyFocus(focusedIndex, in: view)
        view.window?.invalidateCursorRects(for: view)
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

final class FolioPDFView: PDFView {
    var tool: Tool = .pages {
        didSet { if tool != oldValue { window?.invalidateCursorRects(for: self) } }
    }
    var editMark: EditMarkKind = .select {
        didSet { if editMark != oldValue { window?.invalidateCursorRects(for: self) } }
    }
    var pages: [PageRef] = []
    var onMark: ((PageMark, UUID) -> Void)?
    var onRedaction: ((CGRect, UUID) -> Void)?
    var onCrop: ((CGRect, UUID) -> Void)?
    var onSelectMark: ((UUID?) -> Void)?
    var onAskText: (() -> String?)?

    private var dragStart: NSPoint?
    private var strokePoints: [NSPoint] = []
    private let rubber = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        rubber.fillColor = NSColor.systemYellow.withAlphaComponent(0.22).cgColor
        rubber.strokeColor = NSColor.systemYellow.cgColor
        rubber.lineWidth = 1
        rubber.lineCap = .round
        rubber.lineJoin = .round
        layer?.addSublayer(rubber)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        if EditInteraction.usesNativePointer(tool, mark: editMark) {
            addCursorRect(bounds, cursor: .iBeam)
        } else if tool == .edit || tool == .redact {
            addCursorRect(bounds, cursor: .crosshair)
        } else {
            super.resetCursorRects()
        }
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        dragStart = point
        strokePoints = [point]
        if EditInteraction.usesNativePointer(tool, mark: editMark) {
            super.mouseDown(with: event)
            return
        }
        updateRubber(to: point)
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
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
            rubber.path = nil
        }
        if EditInteraction.usesNativePointer(tool, mark: editMark) {
            super.mouseUp(with: event)
            if applyTextSelectionMarks() { return }
            commitAreaIfNeeded(end: end)
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
            return
        }
        if editMark == .textBox {
            guard let text = onAskText?() else { return }
            onMark?(PageMark(kind: .textBox, rect: pageRect, text: text), target.id)
            return
        }
        guard let kind = editMark.markKind else { return }
        onMark?(PageMark(kind: kind, rect: pageRect), target.id)
    }

    private func commitStroke() {
        guard strokePoints.count > 1, let first = strokePoints.first, let target = targetPage(at: first) else { return }
        let pdfPoints = strokePoints.map { convert($0, to: target.page) }
        onMark?(
            PageMark(kind: .stroke, rect: EditGestureMath.strokeBounds(pdfPoints), points: pdfPoints),
            target.id
        )
    }

    private func targetPage(at viewPoint: NSPoint) -> (page: PDFPage, id: UUID)? {
        guard let page = page(for: viewPoint, nearest: true), let document else { return nil }
        let index = document.index(for: page)
        guard let id = ReaderPageIndex.id(at: index, in: pages.map(\.id)) else { return nil }
        return (page, id)
    }

    private func updateRubber(to current: NSPoint) {
        guard let start = dragStart else {
            rubber.path = nil
            return
        }
        if tool == .edit, editMark == .draw {
            let path = CGMutablePath()
            if let first = strokePoints.first {
                path.move(to: first)
                for point in strokePoints.dropFirst() { path.addLine(to: point) }
            }
            rubber.fillColor = nil
            rubber.strokeColor = NSColor.systemRed.cgColor
            rubber.path = path
            return
        }
        let rect = EditGestureMath.rect(from: start, to: current)
        if tool == .redact {
            rubber.fillColor = NSColor(red: 0.761, green: 0.231, blue: 0.133, alpha: 0.28).cgColor
            rubber.strokeColor = NSColor(red: 0.761, green: 0.231, blue: 0.133, alpha: 1).cgColor
        } else if editMark == .crop {
            rubber.fillColor = NSColor(red: 0.761, green: 0.231, blue: 0.133, alpha: 0.08).cgColor
            rubber.strokeColor = NSColor(red: 0.761, green: 0.231, blue: 0.133, alpha: 1).cgColor
        } else if editMark == .textBox {
            rubber.fillColor = NSColor.white.withAlphaComponent(0.85).cgColor
            rubber.strokeColor = NSColor.black.withAlphaComponent(0.3).cgColor
        } else {
            rubber.fillColor = NSColor.systemYellow.withAlphaComponent(0.22).cgColor
            rubber.strokeColor = NSColor.systemYellow.cgColor
        }
        rubber.path = CGPath(rect: rect, transform: nil)
    }
}

import AppKit
import PDFKit
import SwiftUI

struct ReaderView: View {
    @ObservedObject var model: AppModel
    @State private var preview: PDFDocument?
    @State private var pageIDs: [UUID] = []
    @State private var dragStart: CGPoint?
    @State private var dragRect: CGRect?
    @State private var strokePoints: [CGPoint] = []
    @State private var pdfView: PDFView?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if preview != nil {
                    PDFKitView(
                        document: preview,
                        focusedIndex: model.revealFocusedInReader(),
                        onVisiblePage: { index in
                            guard pageIDs.indices.contains(index) else { return }
                            let id = pageIDs[index]
                            if model.workspace.focusedID != id {
                                model.selectPage(id, extend: false)
                            }
                        },
                        pdfView: $pdfView
                    )
                    if model.tool == .redact, let page = model.focusedPage() {
                        redactOverlay(in: geo.size, page: page)
                    }
                    if model.tool == .edit, let page = model.focusedPage() {
                        editOverlay(page: page)
                    }
                } else {
                    Text(L10n.t("error.emptyWorkspace"))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .task(id: ReadDocumentBuilder.token(pages: model.workspace.pages)) {
            await rebuild()
        }
    }

    @MainActor
    private func rebuild() async {
        let pages = model.workspace.pages
        pageIDs = pages.map(\.id)
        if pages.isEmpty {
            preview = nil
            return
        }
        preview = try? ReadDocumentBuilder.build(pages: pages)
    }

    private func redactOverlay(in size: CGSize, page: PageRef) -> some View {
        Canvas { _, _ in
            if let pdfView, let pdfPage = pdfView.currentPage {
                // Drawn below via overlay fills in the gesture canvas.
                _ = pdfPage
            }
        }
        .overlay {
            Canvas { context, _ in
                if let pdfView, let pdfPage = pdfView.currentPage {
                    for redaction in page.redactions {
                        let viewRect = pdfView.convert(redaction.rect, from: pdfPage)
                        context.fill(
                            Path(roundedRect: viewRect, cornerRadius: 2),
                            with: .color(FolioTheme.vermilion.opacity(0.28))
                        )
                    }
                }
                if let dragRect {
                    context.fill(Path(roundedRect: dragRect, cornerRadius: 1), with: .color(FolioTheme.vermilion.opacity(0.28)))
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    if dragStart == nil { dragStart = value.startLocation }
                    let start = dragStart ?? value.startLocation
                    dragRect = CGRect(
                        x: min(start.x, value.location.x),
                        y: min(start.y, value.location.y),
                        width: abs(value.location.x - start.x),
                        height: abs(value.location.y - start.y)
                    )
                }
                .onEnded { _ in
                    if let pdfView, let pdfPage = pdfView.currentPage, let viewRect = dragRect {
                        let pageRect = pdfView.convert(viewRect, to: pdfPage)
                        if pageRect.width > 2, pageRect.height > 2 {
                            model.addRedaction(pageRect, to: page.id)
                        }
                    }
                    dragStart = nil
                    dragRect = nil
                }
        )
        .allowsHitTesting(model.tool == .redact)
    }

    private func editOverlay(page: PageRef) -> some View {
        Canvas { context, canvasSize in
            guard let pdfView, let pdfPage = pdfView.currentPage else { return }
            if let crop = page.cropRect {
                let keep = pdfView.convert(crop, from: pdfPage)
                var veil = Path(CGRect(origin: .zero, size: canvasSize))
                veil.addRect(keep)
                context.fill(veil, with: .color(.black.opacity(0.28)), style: FillStyle(eoFill: true))
                context.stroke(Path(roundedRect: keep, cornerRadius: 1), with: .color(FolioTheme.vermilion), lineWidth: 1)
            }
            for mark in page.marks {
                drawMark(mark, in: context, pdfView: pdfView, pdfPage: pdfPage)
            }
            if model.options.editMark == .draw, strokePoints.count > 1 {
                var path = Path()
                path.addLines(strokePoints)
                context.stroke(path, with: .color(.red.opacity(0.9)), lineWidth: 2)
            } else if let dragRect {
                let preview = Path(roundedRect: dragRect, cornerRadius: 1)
                switch model.options.editMark {
                case .crop:
                    context.stroke(preview, with: .color(FolioTheme.vermilion), lineWidth: 1.5)
                    context.fill(preview, with: .color(FolioTheme.vermilion.opacity(0.08)))
                case .underline:
                    var line = Path()
                    line.move(to: CGPoint(x: dragRect.minX, y: dragRect.maxY - 1))
                    line.addLine(to: CGPoint(x: dragRect.maxX, y: dragRect.maxY - 1))
                    context.stroke(line, with: .color(.yellow), lineWidth: 2)
                case .textBox:
                    context.fill(preview, with: .color(.white.opacity(0.85)))
                    context.stroke(preview, with: .color(.black.opacity(0.28)), lineWidth: 0.6)
                default:
                    context.fill(preview, with: .color(.yellow.opacity(0.25)))
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    if dragStart == nil { dragStart = value.startLocation }
                    let start = dragStart ?? value.startLocation
                    if model.options.editMark == .draw {
                        strokePoints.append(value.location)
                    } else {
                        dragRect = CGRect(
                            x: min(start.x, value.location.x),
                            y: min(start.y, value.location.y),
                            width: abs(value.location.x - start.x),
                            height: abs(value.location.y - start.y)
                        )
                    }
                }
                .onEnded { _ in
                    commitEditMark(page: page)
                    dragStart = nil
                    dragRect = nil
                    strokePoints = []
                }
        )
        .allowsHitTesting(model.tool == .edit)
    }

    private func drawMark(_ mark: PageMark, in context: GraphicsContext, pdfView: PDFView, pdfPage: PDFPage) {
        switch mark.kind {
        case .highlight:
            let viewRect = pdfView.convert(mark.rect, from: pdfPage)
            context.fill(Path(roundedRect: viewRect, cornerRadius: 1), with: .color(.yellow.opacity(0.28)))
        case .underline:
            let viewRect = pdfView.convert(mark.rect, from: pdfPage)
            var path = Path()
            path.move(to: CGPoint(x: viewRect.minX, y: viewRect.maxY - 1))
            path.addLine(to: CGPoint(x: viewRect.maxX, y: viewRect.maxY - 1))
            context.stroke(path, with: .color(.yellow), lineWidth: 2)
        case .textBox:
            let viewRect = pdfView.convert(mark.rect, from: pdfPage)
            context.fill(Path(roundedRect: viewRect, cornerRadius: 2), with: .color(.white.opacity(0.9)))
            context.stroke(Path(roundedRect: viewRect, cornerRadius: 2), with: .color(.black.opacity(0.25)), lineWidth: 0.6)
            if !mark.text.isEmpty {
                let resolved = context.resolve(
                    Text(mark.text)
                        .font(.system(size: max(8, min(14, viewRect.height * 0.45))))
                        .foregroundColor(.black)
                )
                context.draw(resolved, in: viewRect.insetBy(dx: 4, dy: 3))
            }
        case .stroke:
            var path = Path()
            for (index, point) in mark.points.enumerated() {
                let viewPoint = pdfView.convert(CGRect(origin: point, size: CGSize(width: 1, height: 1)), from: pdfPage).origin
                if index == 0 { path.move(to: viewPoint) } else { path.addLine(to: viewPoint) }
            }
            context.stroke(path, with: .color(.red), lineWidth: 2)
        }
    }

    private func commitEditMark(page: PageRef) {
        guard let pdfView, let pdfPage = pdfView.currentPage else { return }
        let kind = model.options.editMark
        if kind == .draw {
            let points = strokePoints.map {
                pdfView.convert(CGRect(origin: $0, size: CGSize(width: 1, height: 1)), to: pdfPage).origin
            }
            guard points.count > 1 else { return }
            let xs = points.map(\.x)
            let ys = points.map(\.y)
            let rect = CGRect(
                x: xs.min() ?? 0,
                y: ys.min() ?? 0,
                width: max(1, (xs.max() ?? 0) - (xs.min() ?? 0)),
                height: max(1, (ys.max() ?? 0) - (ys.min() ?? 0))
            )
            model.addMark(PageMark(kind: .stroke, rect: rect, points: points), to: page.id)
            return
        }
        guard let viewRect = dragRect else { return }
        let pageRect = pdfView.convert(viewRect, to: pdfPage)
        guard pageRect.width > 2, pageRect.height > 2 else { return }
        if kind == .crop {
            model.setCrop(pageRect, on: page.id)
            return
        }
        var text = ""
        if kind == .textBox {
            let alert = NSAlert()
            alert.messageText = L10n.t("edit.textPrompt")
            let field = NSTextField(string: "")
            field.frame = NSRect(x: 0, y: 0, width: 240, height: 24)
            alert.accessoryView = field
            alert.addButton(withTitle: L10n.t("ok"))
            alert.addButton(withTitle: L10n.t("cancel"))
            if alert.runModal() != .alertFirstButtonReturn { return }
            text = field.stringValue
        }
        guard let markKind = kind.markKind else { return }
        model.addMark(PageMark(kind: markKind, rect: pageRect, text: text), to: page.id)
    }
}

struct PDFKitView: NSViewRepresentable {
    var document: PDFDocument?
    var focusedIndex: Int
    var onVisiblePage: (Int) -> Void
    @Binding var pdfView: PDFView?

    func makeCoordinator() -> Coordinator {
        Coordinator(onVisiblePage: onVisiblePage)
    }

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        view.document = document
        view.delegate = context.coordinator
        context.coordinator.install(on: view)
        DispatchQueue.main.async { pdfView = view }
        return view
    }

    func updateNSView(_ view: PDFView, context: Context) {
        context.coordinator.onVisiblePage = onVisiblePage
        if view.document !== document {
            context.coordinator.ignorePageChange = true
            view.document = document
            context.coordinator.ignorePageChange = false
        }
        goToFocusedPage(in: view)
        DispatchQueue.main.async { pdfView = view }
    }

    private func goToFocusedPage(in view: PDFView) {
        guard let document = view.document,
              focusedIndex >= 0,
              focusedIndex < document.pageCount,
              let page = document.page(at: focusedIndex)
        else { return }
        if view.currentPage != page {
            view.go(to: page)
        }
    }

    final class Coordinator: NSObject, PDFViewDelegate {
        var onVisiblePage: (Int) -> Void
        var ignorePageChange = false
        private var observer: NSObjectProtocol?

        init(onVisiblePage: @escaping (Int) -> Void) {
            self.onVisiblePage = onVisiblePage
        }

        func install(on view: PDFView) {
            observer = NotificationCenter.default.addObserver(
                forName: .PDFViewPageChanged,
                object: view,
                queue: .main
            ) { [weak self] notification in
                guard let self, !self.ignorePageChange,
                      let pdfView = notification.object as? PDFView,
                      let page = pdfView.currentPage,
                      let document = pdfView.document
                else { return }
                let index = document.index(for: page)
                if index != NSNotFound {
                    self.onVisiblePage(index)
                }
            }
        }

        deinit {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}

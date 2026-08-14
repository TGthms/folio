import PDFKit
import SwiftUI

struct ReaderView: View {
    @ObservedObject var model: AppModel
    @State private var preview: PDFDocument?
    @State private var pageIDs: [UUID] = []
    @State private var dragStart: CGPoint?
    @State private var dragRect: CGRect?
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

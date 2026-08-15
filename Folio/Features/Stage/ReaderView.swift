import AppKit
import PDFKit
import SwiftUI

struct ReaderView: View {
    @ObservedObject var model: AppModel
    @State private var preview: PDFDocument?
    @State private var pageIDs: [UUID] = []

    var body: some View {
        Group {
            if preview != nil {
                ReaderStage(
                    document: preview,
                    focusedIndex: model.revealFocusedInReader(),
                    tool: model.tool,
                    editMark: model.options.editMark,
                    pages: model.workspace.pages,
                    onVisiblePage: { index in
                        guard let id = ReaderPageIndex.id(at: index, in: pageIDs) else { return }
                        model.revealPageFromReader(id)
                    },
                    onMark: { mark, id in model.addMark(mark, to: id) },
                    onRedaction: { rect, id in model.addRedaction(rect, to: id) },
                    onCrop: { rect, id in model.setCrop(rect, on: id) },
                    onSelectMark: { model.selectedMarkID = $0 },
                    onAskText: { promptForText() }
                )
            } else {
                Text(L10n.t("error.emptyWorkspace"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func promptForText() -> String? {
        let alert = NSAlert()
        alert.messageText = L10n.t("edit.textPrompt")
        let field = NSTextField(string: "")
        field.frame = NSRect(x: 0, y: 0, width: 240, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: L10n.t("ok"))
        alert.addButton(withTitle: L10n.t("cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue
    }
}

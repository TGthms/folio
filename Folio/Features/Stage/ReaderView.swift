import AppKit
import PDFKit
import SwiftUI

struct ReaderView: View {
    @ObservedObject var model: AppModel
    @State private var preview: PDFDocument?
    @State private var pageIDs: [UUID] = []
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
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
                    onReplaceMark: { model.replaceMark($0) },
                    onRedaction: { rect, id in model.addRedaction(rect, to: id) },
                    onCrop: { rect, id in model.setCrop(rect, on: id) },
                    onSelectMark: { model.selectedMarkID = $0 },
                    onRemoveMark: { _ = model.removeMark($0) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(L10n.t("error.emptyWorkspace"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(alignment: .top) {
            if preview != nil, model.tool == .edit {
                EditMarkupBar(mark: $model.options.editMark)
                    .padding(.top, 12)
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
}

struct EditMarkupBar: View {
    @Binding var mark: EditMarkKind
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(EditMarkKind.allCases) { kind in
                Button {
                    mark = kind
                } label: {
                    Image(systemName: kind.symbol)
                        .font(.system(size: 13, weight: mark == kind ? .semibold : .regular))
                        .foregroundStyle(mark == kind ? FolioTheme.vermilion : FolioTheme.ink(for: scheme))
                        .frame(width: 32, height: 28)
                        .background {
                            if mark == kind {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(FolioTheme.vermilion.opacity(0.14))
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(FolioPressStyle())
                .help(L10n.t(kind.titleKey))
                .accessibilityLabel(L10n.t(kind.titleKey))
            }
        }
        .padding(4)
        .background {
            Capsule(style: .continuous)
                .fill(reduceTransparency ? FolioTheme.card(for: scheme) : Color.clear)
        }
        .background(.regularMaterial, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(FolioTheme.rule(for: scheme), lineWidth: 1)
        }
        .shadow(
            color: .black.opacity(scheme == .dark ? 0.32 : 0.10),
            radius: reduceMotion ? 3 : 10,
            y: 2
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.t("tool.edit"))
    }
}

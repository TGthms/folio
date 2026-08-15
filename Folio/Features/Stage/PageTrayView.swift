import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PageTrayView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = [GridItem(.adaptive(minimum: 132, maximum: 180), spacing: 18)]

    private var displayedPages: [PageRef] {
        PageReorder.displayed(
            model.workspace.pages,
            dragging: model.draggingPageID,
            previewDestination: model.dragPreviewDestination
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            rangeBar
            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Array(displayedPages.enumerated()), id: \.element.id) { index, page in
                        PageThumbCell(
                            page: page,
                            index: index,
                            selected: model.workspace.selectedIDs.contains(page.id) || model.workspace.focusedID == page.id,
                            scheme: scheme
                        )
                        .onTapGesture(count: 2) {
                            model.workspace.focusedID = page.id
                            withAnimation(FolioMotion.panel(reduceMotion: reduceMotion)) {
                                model.stageMode = .read
                            }
                        }
                        .onTapGesture {
                            model.selectPage(
                                page.id,
                                extend: NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)
                            )
                        }
                        .onDrag {
                            model.draggingPageID = page.id
                            model.workspace.focusedID = page.id
                            return NSItemProvider(object: page.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text, .fileURL], delegate: PageDropDelegate(model: model, destination: page))
                    }
                }
                .padding(28)
                .environment(\.layoutDirection, .leftToRight)
                .animation(
                    model.draggingPageID == nil ? FolioMotion.snap(reduceMotion: reduceMotion) : nil,
                    value: model.workspace.pages.map(\.id)
                )
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted) { providers in
            ContentDrop.importProviders(providers, into: model)
            return true
        }
    }

    private var rangeBar: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                TextField(L10n.t("pages.selectRangeHint"), text: $model.pageRangeDraft)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)
                    .onSubmit { model.selectPages(range: model.pageRangeDraft) }
                    .accessibilityLabel(L10n.t("pages.selectRangeHint"))
                    .accessibilityHint(L10n.t("pages.selectRangeHelp"))
                Text(L10n.t("pages.selectRangeHelp"))
                    .font(.system(size: 11))
                    .foregroundStyle(FolioTheme.secondaryInk(for: scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(L10n.t("pages.selectRange")) {
                model.selectPages(range: model.pageRangeDraft)
            }
            .controlSize(.regular)
            .disabled(model.pageRangeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(FolioTheme.rule(for: scheme))
                .frame(height: 1)
        }
    }
}

struct PageThumbCell: View {
    let page: PageRef
    let index: Int
    let selected: Bool
    let scheme: ColorScheme
    @State private var image: NSImage?
    @State private var hovering = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(FolioTheme.card(for: scheme))
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .padding(6)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(height: 168)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(selected ? FolioTheme.vermilion : FolioTheme.rule(for: scheme), lineWidth: selected ? 2 : 1)
            )
            .shadow(color: .black.opacity(hovering || selected ? 0.18 : 0.08), radius: hovering || selected ? 10 : 5, y: hovering || selected ? 4 : 2)
            .offset(y: hovering || selected ? -2 : 0)

            Text("\(index + 1)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(selected ? FolioTheme.vermilion : FolioTheme.secondaryInk(for: scheme))
                .monospacedDigit()
        }
        .onHover { hovering = $0 }
        .task(id: "\(page.id.uuidString)-\(page.rotation)-\(page.redactions.count)") {
            image = ThumbnailCache.shared.generate(for: page, size: CGSize(width: 220, height: 300))
        }
    }
}

struct PageDropDelegate: DropDelegate {
    let model: AppModel
    let destination: PageRef

    func performDrop(info: DropInfo) -> Bool {
        if info.hasItemsConforming(to: [.fileURL]) {
            ContentDrop.importProviders(info.itemProviders(for: [.fileURL]), into: model)
            model.cancelPageDrag()
            return true
        }
        model.commitPageDrag()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let fromID = model.draggingPageID ?? model.workspace.focusedID,
              fromID != destination.id,
              let dest = model.workspace.pages.firstIndex(where: { $0.id == destination.id })
        else { return }
        model.previewPageMove(id: fromID, to: dest)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: info.hasItemsConforming(to: [.fileURL]) ? .copy : .move)
    }
}

enum ContentDrop {
    static func importProviders(_ providers: [NSItemProvider], into model: AppModel) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil) ?? URL(string: String(data: data, encoding: .utf8) ?? "")
                } else if let value = item as? URL {
                    url = value
                } else {
                    url = nil
                }
                if let url {
                    Task { @MainActor in
                        model.importURLs([url])
                    }
                }
            }
        }
    }
}

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PageTrayView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let columns = [GridItem(.adaptive(minimum: 132, maximum: 180), spacing: 18)]
    @State private var frames: [UUID: CGRect] = [:]
    @State private var dragLocation: CGPoint?
    @State private var grabOffset: CGSize = .zero
    @State private var liftSize: CGSize = CGSize(width: 120, height: 160)
    @State private var liftImage: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            rangeBar
            ZStack(alignment: .topLeading) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(Array(model.workspace.pages.enumerated()), id: \.element.id) { index, page in
                            PageThumbCell(
                                page: page,
                                index: index,
                                selected: model.workspace.selectedIDs.contains(page.id) || model.workspace.focusedID == page.id,
                                scheme: scheme,
                                dimmed: model.draggingPageID == page.id,
                                liftEnabled: model.draggingPageID == nil
                            )
                            .background(
                                GeometryReader { cell in
                                    Color.clear.preference(
                                        key: ThumbFrameKey.self,
                                        value: [page.id: cell.frame(in: .named("folio.tray"))]
                                    )
                                }
                            )
                            .contentShape(Rectangle())
                            .pointerStyle(model.draggingPageID == page.id ? .grabActive : .grabIdle)
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
                            .simultaneousGesture(pageDrag(page))
                            .onDrop(of: [.fileURL], delegate: FileOnlyDropDelegate(model: model))
                        }
                    }
                    .padding(28)
                    .environment(\.layoutDirection, .leftToRight)
                }
                insertionBar
                liftPreview
            }
            .coordinateSpace(name: "folio.tray")
            .onPreferenceChange(ThumbFrameKey.self) { frames = $0 }
            .transaction { transaction in
                if model.draggingPageID != nil {
                    transaction.animation = nil
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted) { providers in
            ContentDrop.importProviders(providers, into: model)
            return true
        }
        .onChange(of: model.draggingPageID) { _, id in
            if id == nil {
                dragLocation = nil
                liftImage = nil
                grabOffset = .zero
            }
        }
    }

    private func pageDrag(_ page: PageRef) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("folio.tray"))
            .onChanged { value in
                if model.draggingPageID != page.id {
                    model.draggingPageID = page.id
                    model.workspace.focusedID = page.id
                    if let frame = frames[page.id] {
                        liftSize = frame.size
                        grabOffset = CGSize(
                            width: value.startLocation.x - frame.minX,
                            height: value.startLocation.y - frame.minY
                        )
                    }
                    liftImage = ThumbnailCache.shared.image(for: page, size: CGSize(width: 220, height: 300))
                        ?? ThumbnailCache.shared.generate(for: page, size: CGSize(width: 220, height: 300))
                }
                dragLocation = value.location
                model.previewPageMove(id: page.id, to: insertionGap(at: value.location))
            }
            .onEnded { _ in
                model.commitPageDrag()
                dragLocation = nil
                liftImage = nil
                grabOffset = .zero
            }
    }

    private func insertionGap(at point: CGPoint) -> Int {
        let order = model.workspace.pages.map(\.id)
        guard !order.isEmpty else { return 0 }
        var bestIndex: Int?
        var bestScore = CGFloat.greatestFiniteMagnitude
        for (index, id) in order.enumerated() {
            guard let frame = frames[id] else { continue }
            let dx = point.x - frame.midX
            let dy = point.y - frame.midY
            let score = dx * dx + dy * dy
            if score < bestScore {
                bestScore = score
                bestIndex = index
            }
        }
        guard let bestIndex, let frame = frames[order[bestIndex]] else {
            return order.count
        }
        return point.x >= frame.midX ? bestIndex + 1 : bestIndex
    }

    @ViewBuilder
    private var insertionBar: some View {
        if model.draggingPageID != nil, let dest = model.dragPreviewDestination {
            let bar = barFrame(for: dest)
            if !bar.isEmpty {
                Capsule(style: .continuous)
                    .fill(FolioTheme.vermilion)
                    .frame(width: max(3, bar.width), height: max(3, bar.height))
                    .offset(x: bar.minX, y: bar.minY)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private var liftPreview: some View {
        if let point = dragLocation, let image = liftImage, model.draggingPageID != nil {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: liftSize.width, height: liftSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .shadow(
                    color: .black.opacity(reduceMotion ? 0.08 : 0.28),
                    radius: reduceMotion ? 4 : 16,
                    y: reduceMotion ? 1 : 8
                )
                .scaleEffect(reduceMotion ? 1 : 1.03)
                .offset(x: point.x - grabOffset.width, y: point.y - grabOffset.height)
                .allowsHitTesting(false)
        }
    }

    private func barFrame(for gap: Int) -> CGRect {
        let order = model.workspace.pages.map(\.id)
        if gap <= 0, let first = order.first, let frame = frames[first] {
            return CGRect(x: frame.minX - 5, y: frame.minY, width: 3, height: frame.height)
        }
        if gap >= order.count, let last = order.last, let frame = frames[last] {
            return CGRect(x: frame.maxX + 2, y: frame.minY, width: 3, height: frame.height)
        }
        if order.indices.contains(gap), let frame = frames[order[gap]] {
            return CGRect(x: frame.minX - 5, y: frame.minY, width: 3, height: frame.height)
        }
        return .null
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

private struct ThumbFrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] { [:] }
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct PageThumbCell: View {
    let page: PageRef
    let index: Int
    let selected: Bool
    let scheme: ColorScheme
    var dimmed: Bool = false
    var liftEnabled: Bool = true
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
            .shadow(
                color: .black.opacity(dimmed ? 0.02 : (hovering || selected ? 0.18 : 0.08)),
                radius: dimmed ? 1 : (hovering || selected ? 10 : 5),
                y: dimmed ? 0 : (hovering || selected ? 4 : 2)
            )
            .offset(y: !liftEnabled || dimmed || (!hovering && !selected) ? 0 : -2)
            .opacity(dimmed ? 0.16 : 1)

            Text("\(index + 1)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(selected ? FolioTheme.vermilion : FolioTheme.secondaryInk(for: scheme))
                .monospacedDigit()
        }
        .onHover { hovering = liftEnabled && !dimmed ? $0 : false }
        .task(id: "\(page.id.uuidString)-\(page.rotation)-\(page.redactions.count)-\(page.marks.count)-\(page.cropRect?.debugDescription ?? "-")") {
            image = ThumbnailCache.shared.generate(for: page, size: CGSize(width: 220, height: 300))
        }
    }
}

struct FileOnlyDropDelegate: DropDelegate {
    let model: AppModel

    func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: [.fileURL]) else { return false }
        ContentDrop.importProviders(info.itemProviders(for: [.fileURL]), into: model)
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        info.hasItemsConforming(to: [.fileURL]) ? DropProposal(operation: .copy) : nil
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

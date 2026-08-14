import SwiftUI

struct EmptyStateView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            dropWell
            if !model.hasExportedOnce {
                Text(L10n.t("empty.hint"))
                    .font(.system(size: 13))
                    .foregroundStyle(FolioTheme.secondaryInk(for: scheme))
            }
            tileGrid
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dropWell: some View {
        Button {
            model.addFiles()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(FolioTheme.vermilion)
                Text(L10n.t("empty.headline"))
                    .font(FolioTheme.wordmark)
                    .tracking(-0.6)
                    .foregroundStyle(FolioTheme.ink(for: scheme))
                Text(L10n.t("empty.drop"))
                    .font(.system(size: 14))
                    .foregroundStyle(FolioTheme.secondaryInk(for: scheme))
            }
            .frame(maxWidth: 520)
            .padding(.vertical, 48)
            .padding(.horizontal, 28)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FolioTheme.card(for: scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        model.isDropTargeted ? FolioTheme.vermilion : FolioTheme.rule(for: scheme),
                        style: StrokeStyle(lineWidth: model.isDropTargeted ? 2 : 1, dash: [7, 5])
                    )
            )
            .scaleEffect(model.isDropTargeted ? 1.03 : 1)
            .animation(FolioMotion.snap(reduceMotion: reduceMotion), value: model.isDropTargeted)
        }
        .buttonStyle(FolioPressStyle())
    }

    private var tileGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 10)], spacing: 10) {
            ForEach(Tool.allCases) { tool in
                Button {
                    model.selectTool(tool)
                    model.addFiles()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tool.symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(FolioTheme.vermilion)
                        Text(L10n.t(tool.titleKey))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(FolioTheme.ink(for: scheme))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .paperCard(radius: FolioTheme.tileRadius)
                }
                .buttonStyle(FolioPressStyle())
            }
        }
        .frame(maxWidth: 640)
    }
}

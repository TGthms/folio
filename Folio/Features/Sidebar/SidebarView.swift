import SwiftUI

struct SidebarView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Namespace private var toolNS

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t("app.name"))
                .font(FolioTheme.wordmarkSmall)
                .tracking(-0.4)
                .foregroundStyle(FolioTheme.ink(for: scheme))
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    recentsBlock
                    ForEach(ToolGroup.allCases) { group in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.t(group.titleKey))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(FolioTheme.secondaryInk(for: scheme))
                                .padding(.horizontal, 14)
                            ForEach(group.tools) { tool in
                                toolRow(tool)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background {
            if reduceTransparency {
                FolioTheme.card(for: scheme)
            } else {
                Rectangle().fill(.regularMaterial)
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(FolioTheme.rule(for: scheme))
                .frame(width: 1)
        }
        .animation(FolioMotion.snap, value: model.tool)
    }

    private var recentsBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(L10n.t("recents"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(FolioTheme.secondaryInk(for: scheme))
                Spacer()
                if !model.recents.isEmpty {
                    Button(L10n.t("recents.clear")) { model.clearRecents() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(FolioTheme.vermilion)
                }
            }
            .padding(.horizontal, 14)

            if model.recents.isEmpty {
                Text(L10n.t("recents.empty"))
                    .font(.system(size: 12))
                    .foregroundStyle(FolioTheme.secondaryInk(for: scheme))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
            } else {
                ForEach(model.recents.prefix(6)) { item in
                    Button {
                        model.openRecent(item)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc")
                            Text(item.displayName)
                                .lineLimit(1)
                            Spacer()
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(FolioTheme.ink(for: scheme))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(FolioPressStyle())
                }
            }
        }
    }

    private func toolRow(_ tool: Tool) -> some View {
        let selected = model.tool == tool
        return Button {
            model.selectTool(tool)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: tool.symbol)
                    .frame(width: 16)
                Text(L10n.t(tool.titleKey))
                Spacer()
            }
            .font(.system(size: 13, weight: selected ? .semibold : .regular))
            .foregroundStyle(selected ? FolioTheme.vermilion : FolioTheme.ink(for: scheme))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(FolioTheme.vermilion.opacity(0.12))
                        .matchedGeometryEffect(id: "tool-pill", in: toolNS)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(FolioPressStyle())
        .padding(.horizontal, 8)
    }
}

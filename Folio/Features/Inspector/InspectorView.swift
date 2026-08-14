import SwiftUI

struct InspectorView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t(model.tool.titleKey))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(FolioTheme.ink(for: scheme))
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    facts
                    ToolInspectors(model: model)
                    metadata
                    toggles
                    if let banner = model.banner {
                        Text(banner)
                            .font(.system(size: 12))
                            .foregroundStyle(FolioTheme.vermilion)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
            }

            ExportProgressButton(
                title: L10n.t("export"),
                savedTitle: L10n.t("export.saved"),
                progress: model.exportProgress,
                succeeded: model.exportSucceeded,
                enabled: model.canExport
            ) {
                model.export()
            }
            .padding(16)
        }
        .background(FolioTheme.card(for: scheme))
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.t("inspector.document"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(FolioTheme.secondaryInk(for: scheme))
            labeled(L10n.t("inspector.pages"), model.pageCountText)
            labeled(L10n.t("inspector.size"), ByteCountFormatter.string(fromByteCount: model.sourceBytes, countStyle: .file))
            labeled(
                L10n.t("inspector.encrypted"),
                model.sourceWasEncrypted ? L10n.t("inspector.yes") : L10n.t("inspector.no")
            )
            if let output = model.outputBytes {
                labeled(L10n.t("compress.after"), ByteCountFormatter.string(fromByteCount: output, countStyle: .file))
            }
        }
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(L10n.t("metadata.title"), text: $model.options.metadata.title)
            TextField(L10n.t("metadata.author"), text: $model.options.metadata.author)
            TextField(L10n.t("metadata.subject"), text: $model.options.metadata.subject)
        }
        .textFieldStyle(.roundedBorder)
    }

    private var toggles: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(L10n.t("export.flatten"), isOn: $model.options.flattenAnnotations)
            Toggle(L10n.t("export.replace"), isOn: $model.options.replaceOriginal)
        }
        .toggleStyle(.checkbox)
        .font(.system(size: 12))
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(FolioTheme.secondaryInk(for: scheme))
            Spacer()
            Text(value)
        }
        .font(.system(size: 12))
        .foregroundStyle(FolioTheme.ink(for: scheme))
    }
}

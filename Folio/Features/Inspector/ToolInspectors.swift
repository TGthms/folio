import SwiftUI

struct ToolInspectors: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch model.tool {
            case .pages:
                pagesOps
            case .edit:
                editOps
            case .merge:
                Text(L10n.t("merge.help"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            case .split:
                splitOps
            case .compress:
                compressOps
            case .watermark:
                watermarkOps
            case .pageNumbers:
                pageNumberOps
            case .imagesToPDF:
                imagePageOps
            case .pdfToImages:
                imageExportOps
            case .extractText:
                Text(L10n.t("extract.help"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            case .ocr:
                Text(L10n.t("ocr.help"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            case .protect:
                protectOps
            case .unlock:
                Text(L10n.t("unlock.help"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            case .redact:
                redactOps
            }
        }
    }

    private var editOps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("edit.help"))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Picker(L10n.t("tool.edit"), selection: $model.options.editMark) {
                ForEach(EditMarkKind.allCases) { kind in
                    Text(L10n.t(kind.titleKey)).tag(kind)
                }
            }
            Button(L10n.t("edit.crop")) { model.cropSelected() }
            Button(L10n.t("edit.clearCrop")) { model.clearCropOnSelection() }
            Button(L10n.t("edit.replaceImage")) { model.replaceSelectedPageWithImage() }
            Button(L10n.t("edit.clearMarks")) { model.clearMarksOnSelection() }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var pagesOps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("pages.selectRangeHelp"))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField(L10n.t("pages.selectRangeHint"), text: $model.pageRangeDraft)
                .textFieldStyle(.roundedBorder)
                .onSubmit { model.selectPages(range: model.pageRangeDraft) }
            Button(L10n.t("pages.selectRange")) {
                model.selectPages(range: model.pageRangeDraft)
            }
            Button(L10n.t("pages.reverse")) { model.reversePages() }
            Button(L10n.t("pages.duplicate")) { model.duplicateSelected() }
            Button(L10n.t("pages.insertBlank")) { model.insertBlank() }
            Button(L10n.t("pages.removeBlank")) { model.removeBlankPages() }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var splitOps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(L10n.t("split.mode"), selection: $model.options.splitMode) {
                ForEach(SplitMode.allCases) { mode in
                    Text(L10n.t(mode.titleKey)).tag(mode)
                }
            }
            if model.options.splitMode == .ranges {
                TextField(L10n.t("split.rangesHint"), text: $model.options.splitRanges)
                    .textFieldStyle(.roundedBorder)
                Toggle(L10n.t("split.oneFilePerRange"), isOn: $model.options.oneFilePerRange)
            }
            if model.options.splitMode == .every {
                Stepper(value: $model.options.splitEvery, in: 1...999) {
                    Text("\(L10n.t("split.every")): \(model.options.splitEvery)")
                }
            }
        }
        .font(.system(size: 12))
    }

    private var compressOps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(L10n.t("compress.preset"), selection: $model.options.compress) {
                ForEach(CompressPreset.allCases) { preset in
                    Text(L10n.t(preset.titleKey)).tag(preset)
                }
            }
            Toggle(L10n.t("compress.grayscale"), isOn: $model.options.grayscale)
            labeled(L10n.t("compress.before"), L10n.formatBytes(model.sourceBytes))
        }
        .font(.system(size: 12))
    }

    private var watermarkOps: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(L10n.t("watermark.text"), text: $model.options.watermark.text)
                .textFieldStyle(.roundedBorder)
            Picker(L10n.t("watermark.position"), selection: $model.options.watermark.position) {
                ForEach(WatermarkPosition.allCases) { position in
                    Text(L10n.t(position.titleKey)).tag(position)
                }
            }
            Slider(value: $model.options.watermark.opacity, in: 0.05...0.8) {
                Text(L10n.t("watermark.opacity"))
            }
            Slider(value: $model.options.watermark.rotation, in: -90...90) {
                Text(L10n.t("watermark.rotation"))
            }
        }
        .font(.system(size: 12))
    }

    private var pageNumberOps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(L10n.t("pageNumbers.format"), selection: $model.options.pageNumbers.format) {
                ForEach(PageNumberFormat.allCases) { format in
                    Text(L10n.t(format.titleKey)).tag(format)
                }
            }
            Picker(L10n.t("pageNumbers.position"), selection: $model.options.pageNumbers.position) {
                ForEach(PageNumberPosition.allCases) { position in
                    Text(L10n.t(position.titleKey)).tag(position)
                }
            }
            Stepper(value: $model.options.pageNumbers.startAt, in: 0...9999) {
                Text("\(L10n.t("pageNumbers.startAt")): \(model.options.pageNumbers.startAt)")
            }
            Toggle(L10n.t("pageNumbers.skipFirst"), isOn: $model.options.pageNumbers.skipFirst)
        }
        .font(.system(size: 12))
    }

    private var imagePageOps: some View {
        Picker(L10n.t("images.pageSize"), selection: $model.options.imagePageSize) {
            ForEach(ImagePageSize.allCases) { size in
                Text(L10n.t(size.titleKey)).tag(size)
            }
        }
        .font(.system(size: 12))
    }

    private var imageExportOps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker(L10n.t("images.format"), selection: $model.options.imageFormat) {
                Text("PNG").tag(ImageExportFormat.png)
                Text("JPEG").tag(ImageExportFormat.jpeg)
            }
            Picker(L10n.t("images.dpi"), selection: $model.options.imageDPI) {
                Text("72").tag(72)
                Text("144").tag(144)
                Text("300").tag(300)
            }
        }
        .font(.system(size: 12))
    }

    private var protectOps: some View {
        VStack(alignment: .leading, spacing: 8) {
            SecureField(L10n.t("protect.password"), text: $model.options.userPassword)
            SecureField(L10n.t("protect.confirm"), text: $model.options.userPasswordConfirm)
            SecureField(L10n.t("protect.owner"), text: $model.options.ownerPassword)
        }
        .textFieldStyle(.roundedBorder)
    }

    private var redactOps: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("redact.warning"))
                .font(.system(size: 12))
                .foregroundStyle(FolioTheme.vermilion)
            Picker(L10n.t("redact.fill"), selection: $model.options.redactFill) {
                ForEach(RedactFill.allCases) { fill in
                    Text(L10n.t(fill.titleKey)).tag(fill)
                }
            }
            Button(L10n.t("redact.entirePage")) { model.redactEntireSelectedPages() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
    }
}

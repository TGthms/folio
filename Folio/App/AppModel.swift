import AppKit
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published var workspace = WorkspaceState()
    @Published var tool: Tool = .merge
    @Published var stageMode: StageMode = .pages
    @Published var inspectorVisible = true
    @Published var options = ExportOptions()
    @Published var recents: [RecentItem] = []
    @Published var isDropTargeted = false
    @Published var exportProgress: Double?
    @Published var exportSucceeded = false
    @Published var banner: String?
    @Published var passwordPrompt: PasswordPrompt?
    @Published var settingsPresented = false
    @Published var palettePresented = false
    @Published var sourceBytes: Int64 = 0
    @Published var outputBytes: Int64?
    @Published var hasExportedOnce: Bool
    @Published var pendingPasswordURL: URL?
    @Published var draggingPageID: UUID?
    @Published var dragPreviewDestination: Int?
    @Published var pageRangeDraft: String = ""
    @Published var localeGeneration: Int = L10n.generation
    @Published var sourceWasEncrypted = false
    @Published var lastSaveURL: URL?
    @Published private(set) var workspaceEpoch = 0
    @Published private(set) var savedEpoch = 0

    var undoManager: UndoManager?
    private let recentsStore = RecentsStore()
    private var exportTask: Task<Void, Never>?

    var hasUnsavedEdits: Bool {
        !workspace.pages.isEmpty && workspaceEpoch != savedEpoch
    }

    struct PasswordPrompt: Identifiable {
        let id = UUID()
        var url: URL
        var password = ""
    }

    init() {
        hasExportedOnce = UserDefaults.standard.bool(forKey: L10n.exportedOnceKey)
        recents = recentsStore.load()
    }

    var pages: [PageRef] {
        get { workspace.pages }
        set { workspace.pages = newValue }
    }

    var canExport: Bool { !workspace.pages.isEmpty && exportProgress == nil }

    var pageCountText: String {
        L10n.formatPageCount(workspace.pages.count)
    }

    func registerUndo(markDirty: Bool = true) {
        let snapshot = workspace
        let previousEpoch = workspaceEpoch
        if markDirty {
            workspaceEpoch += 1
        }
        undoManager?.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                let current = target.workspace
                let currentEpoch = target.workspaceEpoch
                target.workspace = snapshot
                target.workspaceEpoch = previousEpoch
                target.undoManager?.registerUndo(withTarget: target) { inner in
                    Task { @MainActor in
                        inner.workspace = current
                        inner.workspaceEpoch = currentEpoch
                    }
                }
            }
        }
    }

    /// Finder, `onOpenURL`, Add Files, and drops all enter here.
    func importURLs(_ urls: [URL]) {
        Task { await importURLsAsync(urls) }
    }

    /// Shipped open/import: load every page into the workspace; never writes the source.
    func importURLsAsync(_ urls: [URL]) async {
        for url in urls {
            _ = url.startAccessingSecurityScopedResource()
            if ImageConvertService.isPDF(url) {
                await importPDF(url)
            } else if ImageConvertService.isImage(url) {
                importImage(url)
            }
            rememberRecent(url)
        }
        refreshSourceBytes()
    }

    private func importPDF(_ url: URL) async {
        do {
            let document = try PDFIO.document(at: url)
            var imported: [PageRef] = []
            for index in 0..<document.pageCount {
                imported.append(PageRef(source: .pdf(url: url, pageIndex: index)))
            }
            registerUndo(markDirty: false)
            workspace.append(imported)
        } catch FolioError.encrypted {
            sourceWasEncrypted = true
            passwordPrompt = PasswordPrompt(url: url)
        } catch {
            banner = L10n.t("error.unreadable")
        }
    }

    private func importImage(_ url: URL) {
        registerUndo(markDirty: false)
        workspace.append([PageRef(source: .image(url: url))])
    }

    func submitPassword() {
        guard let prompt = passwordPrompt else { return }
        PDFIO.rememberPassword(prompt.password, for: prompt.url)
        passwordPrompt = nil
        Task { await importPDF(prompt.url) }
    }

    func addFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.pdf, .image, .png, .jpeg, .tiff, .heic]
        if panel.runModal() == .OK {
            importURLs(panel.urls)
        }
    }

    func rotate(by degrees: Int) {
        registerUndo()
        workspace.rotateSelected(by: degrees)
    }

    func deleteSelected() {
        registerUndo()
        workspace.deleteSelected()
        refreshSourceBytes()
    }

    func reversePages() {
        registerUndo()
        workspace.reverse()
    }

    func duplicateSelected() {
        registerUndo()
        workspace.duplicateSelected()
    }

    func insertBlank() {
        registerUndo()
        let index = workspace.pages.firstIndex(where: { $0.id == workspace.focusedID }).map { $0 + 1 } ?? workspace.pages.count
        workspace.insertBlank(at: index)
    }

    func removeBlankPages() {
        registerUndo()
        workspace.pages.removeAll { page in
            guard let pdf = try? PDFIO.page(for: page) else { return false }
            return TextService.isNearlyBlank(pdf)
        }
    }

    func movePage(id: UUID, to destination: Int) {
        registerUndo()
        workspace.move(id: id, to: destination)
    }

    func applyLanguage(_ code: String?) {
        L10n.apply(code)
        localeGeneration = L10n.generation
    }

    func previewPageMove(id: UUID, to destination: Int) {
        if dragPreviewDestination != destination {
            dragPreviewDestination = destination
        }
    }

    func commitPageDrag() {
        guard let id = draggingPageID, let dest = dragPreviewDestination else {
            cancelPageDrag()
            return
        }
        let next = PageReorder.move(workspace.pages, id: id, to: dest)
        if next.map(\.id) != workspace.pages.map(\.id) {
            registerUndo()
            workspace.pages = next
            workspace.focusedID = id
        }
        cancelPageDrag()
    }

    func cancelPageDrag() {
        draggingPageID = nil
        dragPreviewDestination = nil
    }

    func selectPages(range: String) {
        do {
            workspace = try PageSelection.select(range: range, in: workspace)
        } catch {
            banner = L10n.t("error.invalidRange")
        }
    }

    func redactEntireSelectedPages() {
        registerUndo()
        workspace.redactSelectedPages()
    }

    func addRedaction(_ rect: CGRect, to id: UUID) {
        registerUndo()
        workspace.addRedaction(Redaction(rect: rect), to: id)
    }

    func selectTool(_ next: Tool) {
        let enteringEdit = next == .edit && tool != .edit
        withAnimation(FolioMotion.snap) {
            tool = next
            if enteringEdit, !workspace.pages.isEmpty {
                stageMode = .read
            }
        }
    }

    /// Scroll in Read only moves the focus ring. It must not wipe a multi-page selection.
    func revealPageFromReader(_ id: UUID) {
        if workspace.focusedID != id {
            workspace.focusedID = id
        }
    }

    func addMark(_ mark: PageMark, to id: UUID) {
        registerUndo()
        workspace.addMark(mark, to: id)
    }

    func cropSelected() {
        registerUndo()
        for id in workspace.effectiveSelection() {
            guard let page = workspace.pages.first(where: { $0.id == id }),
                  let pdf = try? PDFIO.page(for: page)
            else { continue }
            let bounds = pdf.bounds(for: .mediaBox)
            let inset = min(36, min(bounds.width, bounds.height) * 0.08)
            workspace.setCrop(bounds.insetBy(dx: inset, dy: inset), on: [id])
        }
    }

    func setCrop(_ rect: CGRect, on id: UUID) {
        registerUndo()
        workspace.setCrop(rect, on: [id])
    }

    func clearCropOnSelection() {
        registerUndo()
        workspace.setCrop(nil, on: workspace.effectiveSelection())
    }

    func clearMarksOnSelection() {
        registerUndo()
        workspace.clearMarks(on: workspace.effectiveSelection())
    }

    func replaceSelectedPageWithImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic, .image]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        _ = url.startAccessingSecurityScopedResource()
        registerUndo()
        let target = workspace.focusedID ?? workspace.pages.first?.id
        if let target {
            workspace.replaceSource(.image(url: url), on: target)
        }
        refreshSourceBytes()
    }

    func saveDocument() {
        guard canExport else {
            banner = L10n.t("error.emptyWorkspace")
            return
        }
        let destination: URL?
        do {
            destination = try resolveSaveDestination(promptIfNeeded: false)
        } catch {
            return
        }
        let url = destination
        if let url, writesOriginal(url) || options.replaceOriginal {
            let alert = NSAlert()
            alert.messageText = L10n.t("export.replaceConfirm")
            alert.informativeText = L10n.t("export.replaceMessage")
            alert.addButton(withTitle: L10n.t("ok"))
            alert.addButton(withTitle: L10n.t("cancel"))
            if alert.runModal() != .alertFirstButtonReturn { return }
        }
        exportTask?.cancel()
        exportTask = Task { await performSave() }
    }

    private func writesOriginal(_ url: URL) -> Bool {
        let target = url.standardizedFileURL
        return workspace.pages.contains { $0.sourceURL?.standardizedFileURL == target }
    }

    private func resolveSaveDestination(promptIfNeeded: Bool) throws -> URL? {
        if options.replaceOriginal, let original = workspace.pages.first?.sourceURL {
            return original
        }
        if let lastSaveURL {
            return lastSaveURL
        }
        if promptIfNeeded {
            return try pickDestinations(count: 1, ext: "pdf", suffixOverride: L10n.suffix(for: .edit))[0]
        }
        return nil
    }

    private func performSave() async {
        exportSucceeded = false
        exportProgress = 0
        banner = nil
        do {
            let destination: URL
            if let known = try resolveSaveDestination(promptIfNeeded: true) {
                destination = known
            } else {
                throw FolioError.cancelled
            }
            let document = try await PDFBuilder.build(pages: workspace.pages, tool: .edit, options: options) { value in
                Task { @MainActor in
                    self.exportProgress = value
                }
            }
            var writeOptions = options
            writeOptions.userPassword = ""
            writeOptions.ownerPassword = ""
            try await PDFIO.write(document, to: destination, options: writeOptions, applyOCROption: false)
            lastSaveURL = destination
            savedEpoch = workspaceEpoch
            outputBytes = PDFIO.fileSize(at: destination)
            exportProgress = 1
            exportSucceeded = true
            hasExportedOnce = true
            UserDefaults.standard.set(true, forKey: L10n.exportedOnceKey)
            try? await Task.sleep(for: .milliseconds(1400))
            exportSucceeded = false
            exportProgress = nil
        } catch is CancellationError {
            exportProgress = nil
            banner = L10n.t("error.cancelled")
        } catch let error as FolioError {
            exportProgress = nil
            banner = L10n.t(error.localizationKey)
        } catch {
            exportProgress = nil
            banner = L10n.t("error.writeFailed")
        }
    }

    func export() {
        guard canExport else {
            banner = L10n.t("error.emptyWorkspace")
            return
        }
        if tool == .protect, options.userPassword != options.userPasswordConfirm {
            banner = L10n.t("error.passwordMismatch")
            return
        }
        if tool == .protect, options.userPassword.isEmpty {
            banner = L10n.t("error.noPassword")
            return
        }
        if tool == .unlock, firstPassword() == nil {
            banner = L10n.t("error.noPassword")
            return
        }

        if options.replaceOriginal {
            let alert = NSAlert()
            alert.messageText = L10n.t("export.replaceConfirm")
            alert.informativeText = L10n.t("export.replaceMessage")
            alert.addButton(withTitle: L10n.t("ok"))
            alert.addButton(withTitle: L10n.t("cancel"))
            if alert.runModal() != .alertFirstButtonReturn { return }
        }

        exportTask?.cancel()
        exportTask = Task { await performExport() }
    }

    private func performExport() async {
        exportSucceeded = false
        exportProgress = 0
        banner = nil
        do {
            let groups = try exportGroups()
            if tool == .extractText {
                try await exportText(groups: groups)
            } else if tool == .pdfToImages {
                try await exportImages(groups: groups)
            } else {
                try await exportPDFs(groups: groups)
            }
            exportProgress = 1
            exportSucceeded = true
            hasExportedOnce = true
            UserDefaults.standard.set(true, forKey: L10n.exportedOnceKey)
            try? await Task.sleep(for: .milliseconds(1400))
            exportSucceeded = false
            exportProgress = nil
        } catch is CancellationError {
            exportProgress = nil
            banner = L10n.t("error.cancelled")
        } catch let error as FolioError {
            exportProgress = nil
            banner = L10n.t(error.localizationKey)
        } catch {
            exportProgress = nil
            banner = L10n.t("error.writeFailed")
        }
    }

    private func exportGroups() throws -> [[PageRef]] {
        switch tool {
        case .split:
            let mode: SplitPlanner.Mode
            switch options.splitMode {
            case .selected: mode = .selected
            case .ranges: mode = .ranges(options.splitRanges, oneFilePerRange: options.oneFilePerRange)
            case .every: mode = .every(max(1, options.splitEvery))
            case .eachPage: mode = .eachPage
            }
            return try SplitPlanner.plan(pages: workspace.pages, selected: workspace.selectedIDs, mode: mode)
        default:
            return try SplitPlanner.plan(pages: workspace.pages, selected: workspace.selectedIDs, mode: .singleFile)
        }
    }

    private func exportPDFs(groups: [[PageRef]]) async throws {
        let destinations = try pickDestinations(count: groups.count, ext: "pdf")
        var lastSize: Int64 = 0
        for (index, group) in groups.enumerated() {
            try Task.checkCancellation()
            var writeOptions = options
            if tool != .protect {
                writeOptions.userPassword = ""
                writeOptions.ownerPassword = ""
            }
            let document = try await PDFBuilder.build(pages: group, tool: tool, options: writeOptions) { value in
                Task { @MainActor in
                    self.exportProgress = (Double(index) + value) / Double(groups.count)
                }
            }
            let applyOCR = tool == .ocr
            try await PDFIO.write(document, to: destinations[index], options: writeOptions, applyOCROption: applyOCR)
            lastSize = PDFIO.fileSize(at: destinations[index])
        }
        if destinations.count == 1 {
            lastSaveURL = destinations[0]
        }
        savedEpoch = workspaceEpoch
        outputBytes = lastSize
    }

    private func exportText(groups: [[PageRef]]) async throws {
        let destinations = try pickDestinations(count: 1, ext: "txt")
        var pages: [PDFPage] = []
        for ref in groups.flatMap({ $0 }) {
            pages.append(try PDFIO.page(for: ref))
        }
        let text = TextService.extract(from: pages)
        try text.write(to: destinations[0], atomically: true, encoding: .utf8)
        outputBytes = Int64(text.utf8.count)
        exportProgress = 1
    }

    private func exportImages(groups: [[PageRef]]) async throws {
        let pages = groups.flatMap { $0 }
        let destinations = try pickDestinations(
            count: pages.count,
            ext: options.imageFormat.fileExtension,
            numbered: true
        )
        for (index, ref) in pages.enumerated() {
            try Task.checkCancellation()
            let page = try PDFIO.page(for: ref)
            guard let data = ImageConvertService.render(page, dpi: CGFloat(options.imageDPI), format: options.imageFormat) else {
                throw FolioError.writeFailed
            }
            try data.write(to: destinations[index])
            exportProgress = Double(index + 1) / Double(pages.count)
        }
        if let last = destinations.last {
            outputBytes = PDFIO.fileSize(at: last)
        }
    }

    private func pickDestinations(
        count: Int,
        ext: String,
        numbered: Bool = false,
        suffixOverride: String? = nil
    ) throws -> [URL] {
        if options.replaceOriginal, let original = workspace.pages.first?.sourceURL, count == 1 {
            return [original]
        }
        let stem = ExportFilename.stem(from: workspace.pages.first?.sourceURL)
        let suffix: String
        if numbered {
            suffix = ""
        } else if let suffixOverride {
            suffix = suffixOverride
        } else if count == 1 {
            suffix = L10n.suffix(for: tool)
        } else {
            suffix = L10n.suffix(for: .split)
        }

        if count == 1 {
            let panel = NSSavePanel()
            panel.canCreateDirectories = true
            panel.nameFieldStringValue = ExportFilename.make(
                base: stem,
                suffix: numbered ? "" : suffix,
                ext: ext,
                existingNames: []
            )
            panel.allowedContentTypes = [UTType(filenameExtension: ext) ?? .data]
            guard panel.runModal() == .OK, let url = panel.url else { throw FolioError.cancelled }
            return [url]
        }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = L10n.t("export")
        guard panel.runModal() == .OK, let folder = panel.url else { throw FolioError.cancelled }
        var existing = ExportFilename.namesOnDisk(in: folder)
        var urls: [URL] = []
        for index in 0..<count {
            let itemSuffix: String
            if numbered {
                itemSuffix = String(format: "-%03d", index + 1)
            } else {
                itemSuffix = ExportFilename.partSuffix(template: suffix, index: index + 1)
            }
            let name = ExportFilename.make(base: stem, suffix: itemSuffix, ext: ext, existingNames: existing)
            existing.insert(name)
            urls.append(folder.appendingPathComponent(name))
        }
        return urls
    }

    func printDocument() {
        Task {
            do {
                let document = try await PDFBuilder.build(pages: workspace.pages, tool: .pages, options: options)
                guard document.pageCount > 0 else { return }
                let pdfView = PDFView(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
                pdfView.document = document
                pdfView.autoScales = true
                pdfView.displayMode = .singlePageContinuous
                let operation = NSPrintOperation(view: pdfView, printInfo: .shared)
                operation.showsPrintPanel = true
                operation.showsProgressPanel = true
                operation.run()
            } catch {
                banner = L10n.t("error.writeFailed")
            }
        }
    }

    func openRecent(_ item: RecentItem) {
        var stale = false
        if let url = try? URL(
            resolvingBookmarkData: item.bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) {
            _ = url.startAccessingSecurityScopedResource()
            importURLs([url])
        }
    }

    func clearRecents() {
        recents = []
        recentsStore.save(recents)
    }

    func focusedPage() -> PageRef? {
        if let id = workspace.focusedID {
            return workspace.pages.first(where: { $0.id == id })
        }
        return workspace.pages.first
    }

    func selectPage(_ id: UUID, extend: Bool) {
        workspace.focusedID = id
        if extend {
            workspace.selectedIDs.insert(id)
        } else {
            workspace.selectedIDs = [id]
        }
    }

    func navigate(_ command: WorkspaceNavCommand) {
        workspace = WorkspaceNavigation.apply(command, to: workspace)
    }

    func selectAllPages() {
        workspace.selectAll()
    }

    func revealFocusedInReader() -> Int {
        WorkspaceNavigation.focusedIndex(in: workspace) ?? 0
    }

    func refreshSourceBytes() {
        let urls = Set(workspace.pages.compactMap(\.sourceURL))
        sourceBytes = urls.reduce(0) { $0 + PDFIO.fileSize(at: $1) }
    }

    private func rememberRecent(_ url: URL) {
        recents.removeAll { $0.url == url }
        if let item = recentsStore.makeItem(for: url) {
            recents.insert(item, at: 0)
            recentsStore.save(recents)
        }
    }

    private func firstPassword() -> String? {
        for page in workspace.pages {
            if let url = page.sourceURL, let password = PDFIO.password(for: url) {
                return password
            }
        }
        return nil
    }
}

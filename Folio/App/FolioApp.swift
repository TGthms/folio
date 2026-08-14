import SwiftUI

@main
struct FolioApp: App {
    @StateObject private var model = AppModel()

    init() {
        L10n.applyOverrideAtLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .environment(\.layoutDirection, L10n.isRTL ? .rightToLeft : .leftToRight)
                .tint(FolioTheme.vermilion)
                .onAppear {
                    NSApp.appearance = nil
                }
        }
        .defaultSize(width: 1320, height: 840)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(L10n.t("menu.open")) { model.addFiles() }
                    .keyboardShortcut("o", modifiers: [.command])
                Button(L10n.t("menu.export")) { model.export() }
                    .keyboardShortcut("s", modifiers: [.command])
                    .disabled(!model.canExport)
            }
            CommandGroup(replacing: .printItem) {
                Button(L10n.t("menu.print")) { model.printDocument() }
                    .keyboardShortcut("p", modifiers: [.command])
                    .disabled(model.workspace.pages.isEmpty)
            }
            CommandGroup(after: .pasteboard) {
                Button(L10n.t("nav.selectAll")) { model.selectAllPages() }
                    .keyboardShortcut("a", modifiers: [.command])
                    .disabled(model.workspace.pages.isEmpty)
            }
            CommandGroup(after: .undoRedo) {
                Button(L10n.t("toolbar.rotate")) { model.rotate(by: 90) }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(model.workspace.pages.isEmpty)
                Button(L10n.t("toolbar.rotateCCW")) { model.rotate(by: -90) }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                    .disabled(model.workspace.pages.isEmpty)
                Button(L10n.t("toolbar.delete")) { model.deleteSelected() }
                    .keyboardShortcut(.delete, modifiers: [.command])
                    .disabled(model.workspace.pages.isEmpty)
            }
            CommandMenu(L10n.t("menu.go")) {
                Button(L10n.t("nav.next")) { model.navigate(.next) }
                    .keyboardShortcut("]", modifiers: [.command])
                    .disabled(model.workspace.pages.isEmpty)
                Button(L10n.t("nav.previous")) { model.navigate(.previous) }
                    .keyboardShortcut("[", modifiers: [.command])
                    .disabled(model.workspace.pages.isEmpty)
                Divider()
                Button(L10n.t("nav.first")) { model.navigate(.first) }
                    .keyboardShortcut(.upArrow, modifiers: [.command, .option])
                    .disabled(model.workspace.pages.isEmpty)
                Button(L10n.t("nav.last")) { model.navigate(.last) }
                    .keyboardShortcut(.downArrow, modifiers: [.command, .option])
                    .disabled(model.workspace.pages.isEmpty)
            }
            CommandMenu(L10n.t("menu.tools")) {
                ForEach(Tool.allCases) { tool in
                    Button(L10n.t(tool.titleKey)) { model.selectTool(tool) }
                }
            }
            CommandGroup(after: .sidebar) {
                Button(L10n.t("stage.pages")) { model.stageMode = .pages }
                    .keyboardShortcut("1", modifiers: [.command])
                Button(L10n.t("stage.read")) { model.stageMode = .read }
                    .keyboardShortcut("2", modifiers: [.command])
                Button(L10n.t("toolbar.inspector")) {
                    withAnimation(FolioMotion.panel) { model.inspectorVisible.toggle() }
                }
                .keyboardShortcut("i", modifiers: [.command])
                Button(L10n.t("command.palette")) { model.palettePresented = true }
                    .keyboardShortcut("k", modifiers: [.command])
            }
            CommandGroup(replacing: .help) {
                Button(L10n.t("menu.help")) {}
            }
        }

        Settings {
            SettingsView(model: model)
                .frame(width: 420, height: 220)
        }
    }
}

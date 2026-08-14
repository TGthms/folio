import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.undoManager) private var undoManager
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                SidebarView(model: model)
                    .frame(width: FolioTheme.sidebarWidth)
                StageView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if model.inspectorVisible {
                    InspectorView(model: model)
                        .frame(width: FolioTheme.inspectorWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .background(PaperBackground())
            .animation(FolioMotion.panel(reduceMotion: reduceMotion), value: model.inspectorVisible)

            if model.palettePresented {
                CommandPalette(model: model)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .animation(FolioMotion.snap(reduceMotion: reduceMotion), value: model.palettePresented)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                Picker(L10n.t("stage.pages"), selection: $model.stageMode) {
                    Text(L10n.t("stage.pages")).tag(StageMode.pages)
                    Text(L10n.t("stage.read")).tag(StageMode.read)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                .disabled(model.workspace.pages.isEmpty)
            }
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    model.rotate(by: -90)
                } label: {
                    Image(systemName: "rotate.left")
                }
                .help(L10n.t("toolbar.rotateCCW"))
                .disabled(model.workspace.pages.isEmpty)

                Button {
                    model.rotate(by: 90)
                } label: {
                    Image(systemName: "rotate.right")
                }
                .help(L10n.t("toolbar.rotate"))
                .disabled(model.workspace.pages.isEmpty)

                Button {
                    model.deleteSelected()
                } label: {
                    Image(systemName: "trash")
                }
                .help(L10n.t("toolbar.delete"))
                .disabled(model.workspace.pages.isEmpty)

                Button {
                    model.addFiles()
                } label: {
                    Image(systemName: "plus")
                }
                .help(L10n.t("toolbar.addFiles"))

                Button {
                    withAnimation(FolioMotion.panel(reduceMotion: reduceMotion)) {
                        model.inspectorVisible.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
                .help(L10n.t("toolbar.inspector"))

                Button {
                    model.settingsPresented = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help(L10n.t("toolbar.settings"))
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
        .onAppear { model.undoManager = undoManager }
        .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted) { providers in
            ContentDrop.importProviders(providers, into: model)
            return true
        }
        .onOpenURL { url in
            model.importURLs([url])
        }
        .sheet(item: $model.passwordPrompt) { _ in
            PasswordSheet(model: model)
        }
        .sheet(isPresented: $model.settingsPresented) {
            SettingsView(model: model)
                .frame(width: 440, height: 268)
        }
        .focusable()
        .focusEffectDisabled()
        .onDeleteCommand { model.deleteSelected() }
        .onMoveCommand { direction in
            switch direction {
            case .down, .right:
                model.navigate(.next)
            case .up, .left:
                model.navigate(.previous)
            default:
                break
            }
        }
        .onKeyPress(KeyEquivalent("j")) {
            model.navigate(.next)
            return .handled
        }
        .onKeyPress(KeyEquivalent("k")) {
            model.navigate(.previous)
            return .handled
        }
        .onKeyPress { press in
            switch press.key {
            case KeyEquivalent(Character(UnicodeScalar(UInt32(NSHomeFunctionKey))!)):
                model.navigate(.first)
                return .handled
            case KeyEquivalent(Character(UnicodeScalar(UInt32(NSEndFunctionKey))!)):
                model.navigate(.last)
                return .handled
            case KeyEquivalent(Character(UnicodeScalar(UInt32(NSPageDownFunctionKey))!)):
                model.navigate(.next)
                return .handled
            case KeyEquivalent(Character(UnicodeScalar(UInt32(NSPageUpFunctionKey))!)):
                model.navigate(.previous)
                return .handled
            default:
                return .ignored
            }
        }
        .onExitCommand {
            if model.palettePresented { model.palettePresented = false }
        }
    }
}

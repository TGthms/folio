import SwiftUI

struct StageView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            FolioTheme.paper(for: scheme)
            if model.workspace.pages.isEmpty {
                EmptyStateView(model: model)
                    .transition(.opacity)
            } else if model.stageMode == .read {
                ReaderView(model: model)
                    .transition(.opacity)
            } else {
                PageTrayView(model: model)
                    .transition(.opacity)
            }
        }
        .animation(FolioMotion.panel(reduceMotion: reduceMotion), value: model.workspace.pages.isEmpty)
        .animation(FolioMotion.panel(reduceMotion: reduceMotion), value: model.stageMode)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(FolioTheme.rule(for: scheme))
                .frame(width: 1)
        }
    }
}

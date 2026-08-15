import SwiftUI

struct CommandPalette: View {
    @ObservedObject var model: AppModel
    @State private var query = ""
    @FocusState private var queryFocused: Bool
    @Environment(\.colorScheme) private var scheme

    private var matches: [PaletteItem] {
        let items = Tool.allCases.map {
            PaletteItem(id: $0.rawValue, title: L10n.t($0.titleKey), symbol: $0.symbol, kind: .tool($0))
        } + [
            PaletteItem(id: "add", title: L10n.t("command.addFiles"), symbol: "plus", kind: .add),
            PaletteItem(id: "save", title: L10n.t("command.save"), symbol: "square.and.arrow.down", kind: .save),
            PaletteItem(id: "export", title: L10n.t("command.export"), symbol: "square.and.arrow.up", kind: .export),
        ] + model.recents.prefix(8).map {
            PaletteItem(id: $0.id.uuidString, title: $0.displayName, symbol: "doc", kind: .recent($0))
        }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if needle.isEmpty { return items }
        return items.filter { $0.title.lowercased().contains(needle) }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { model.palettePresented = false }
            VStack(spacing: 0) {
                TextField(L10n.t("command.palette"), text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .padding(14)
                    .focused($queryFocused)
                    .onAppear { queryFocused = true }
                Divider()
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(matches) { item in
                            Button {
                                run(item)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: item.symbol)
                                    Text(item.title)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(FolioPressStyle())
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
            .frame(width: 440)
            .paperCard(radius: 16)
            .padding(.top, 72)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func run(_ item: PaletteItem) {
        switch item.kind {
        case .tool(let tool):
            model.selectTool(tool)
        case .add:
            model.addFiles()
        case .save:
            model.saveDocument()
        case .export:
            model.export()
        case .recent(let recent):
            model.openRecent(recent)
        }
        model.palettePresented = false
    }
}

struct PaletteItem: Identifiable {
    enum Kind {
        case tool(Tool)
        case add
        case save
        case export
        case recent(RecentItem)
    }

    var id: String
    var title: String
    var symbol: String
    var kind: Kind
}

import SwiftUI

enum FolioTheme {
    static let sidebarWidth: CGFloat = 240
    static let inspectorWidth: CGFloat = 320
    static let paperRadius: CGFloat = 14
    static let tileRadius: CGFloat = 12

    static let paperLight = Color(red: 0.957, green: 0.937, blue: 0.902) // #F4EFE6
    static let inkLight = Color(red: 0.110, green: 0.098, blue: 0.082) // #1C1915
    static let ruleLight = Color(red: 0.110, green: 0.098, blue: 0.082).opacity(0.14)

    static let paperDark = Color(red: 0.086, green: 0.078, blue: 0.067) // #161411
    static let cardDark = Color(red: 0.133, green: 0.118, blue: 0.098) // #221E19
    static let inkDark = Color(red: 0.953, green: 0.933, blue: 0.902) // #F3EEE6

    static let vermilion = Color(red: 0.761, green: 0.231, blue: 0.133) // #C23B22

    static func paper(for scheme: ColorScheme) -> Color {
        scheme == .dark ? paperDark : paperLight
    }

    static func card(for scheme: ColorScheme) -> Color {
        scheme == .dark ? cardDark : Color(red: 0.976, green: 0.961, blue: 0.933)
    }

    static func ink(for scheme: ColorScheme) -> Color {
        scheme == .dark ? inkDark : inkLight
    }

    static func secondaryInk(for scheme: ColorScheme) -> Color {
        ink(for: scheme).opacity(0.62)
    }

    static func rule(for scheme: ColorScheme) -> Color {
        scheme == .dark ? inkDark.opacity(0.12) : ruleLight
    }

    static let wordmark = Font.system(size: 34, weight: .semibold, design: .serif)
    static let wordmarkSmall = Font.system(size: 18, weight: .semibold, design: .serif)
}

struct PaperBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            FolioTheme.paper(for: scheme)
        } else {
            FolioTheme.paper(for: scheme)
        }
    }
}

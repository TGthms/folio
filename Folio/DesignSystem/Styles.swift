import SwiftUI

struct FolioPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(FolioMotion.press, value: configuration.isPressed)
    }
}

struct PaperCard: ViewModifier {
    var radius: CGFloat = FolioTheme.paperRadius
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(FolioTheme.card(for: scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(FolioTheme.rule(for: scheme), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(scheme == .dark ? 0.35 : 0.08), radius: 10, y: 3)
    }
}

extension View {
    func paperCard(radius: CGFloat = FolioTheme.paperRadius) -> some View {
        modifier(PaperCard(radius: radius))
    }
}

struct ExportProgressButton: View {
    let title: String
    let savedTitle: String
    let progress: Double?
    let succeeded: Bool
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(FolioTheme.vermilion.opacity(enabled || progress != nil ? 1 : 0.45))
                if let progress {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.white.opacity(0.22))
                            .frame(width: geo.size.width * max(0, min(1, progress)))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                HStack(spacing: 8) {
                    if succeeded {
                        Image(systemName: "checkmark")
                    }
                    Text(succeeded ? savedTitle : title)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            }
            .frame(height: 36)
        }
        .buttonStyle(FolioPressStyle())
        .disabled(!enabled && progress == nil)
        .accessibilityLabel(title)
    }
}

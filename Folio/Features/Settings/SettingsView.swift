import SwiftUI

enum FolioLinks {
    static let repository = URL(string: "https://github.com/TGthms/folio")!
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var language: String = L10n.overrideCode ?? "system"

    var body: some View {
        let _ = model.localeGeneration
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.t("settings.title"))
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("settings.language"))
                    .font(.system(size: 12, weight: .medium))
                Picker(L10n.t("settings.language"), selection: $language) {
                    Text(L10n.languageName(for: "system")).tag("system")
                    ForEach(L10n.supportedCodes, id: \.self) { code in
                        Text(L10n.languageName(for: code)).tag(code)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(model.localeGeneration)
                .onChange(of: language) { _, newValue in
                    model.applyLanguage(newValue == "system" ? nil : newValue)
                }
                Text(L10n.t("settings.language.relaunch"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.t("settings.copyright"))
                Spacer(minLength: 12)
                Link(destination: FolioLinks.repository) {
                    HStack(spacing: 4) {
                        Text(L10n.t("settings.repo"))
                        Image(systemName: "arrow.up.right")
                    }
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button(L10n.t("done")) {
                    SettingsDismissal.applyAndDismiss(language: language, model: model)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
    }
}

struct PasswordSheet: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("password.prompt"))
                .font(.headline)
            SecureField(L10n.t("password.unlock"), text: binding)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button(L10n.t("cancel")) { model.passwordPrompt = nil }
                Button(L10n.t("ok")) { model.submitPassword() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    private var binding: Binding<String> {
        Binding(
            get: { model.passwordPrompt?.password ?? "" },
            set: { model.passwordPrompt?.password = $0 }
        )
    }
}

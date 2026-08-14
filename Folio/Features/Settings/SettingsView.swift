import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @State private var language: String = L10n.overrideCode ?? "system"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t("settings.title"))
                .font(.system(size: 18, weight: .semibold))
            Picker(L10n.t("settings.language"), selection: $language) {
                Text(L10n.t("settings.language.system")).tag("system")
                ForEach(L10n.supportedCodes, id: \.self) { code in
                    Text(L10n.languageName(for: code)).tag(code)
                }
            }
            Text(L10n.t("settings.language.relaunch"))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(L10n.t("settings.copyright"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button(L10n.t("done")) {
                    L10n.overrideCode = language == "system" ? nil : language
                    model.settingsPresented = false
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

import Foundation
import SwiftUI

enum L10n {
    static let overrideKey = "folio.languageOverride"
    static let exportedOnceKey = "folio.hasExportedOnce"

    static let supportedCodes: [String] = [
        "en", "es", "fr", "de", "it", "pt-BR", "pt-PT", "nl", "da", "sv", "nb", "fi",
        "pl", "cs", "hu", "ro", "el", "tr", "ru", "uk", "ar", "he", "hi", "th", "vi",
        "id", "ja", "ko", "zh-Hans", "zh-Hant",
    ]

    static let rtlCodes: Set<String> = ["ar", "he"]

    static var overrideCode: String? {
        get {
            let value = UserDefaults.standard.string(forKey: overrideKey)
            return (value?.isEmpty ?? true) ? nil : value
        }
        set {
            if let newValue, !newValue.isEmpty {
                UserDefaults.standard.set(newValue, forKey: overrideKey)
            } else {
                UserDefaults.standard.removeObject(forKey: overrideKey)
            }
        }
    }

    static func applyOverrideAtLaunch() {
        if let code = overrideCode {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    static var effectiveCode: String {
        if let overrideCode { return overrideCode }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred
    }

    static var isRTL: Bool {
        let code = effectiveCode
        if rtlCodes.contains(code) { return true }
        if let language = Locale.Language(identifier: code).languageCode?.identifier {
            return rtlCodes.contains(language)
        }
        return false
    }

    static func t(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }

    static func t(_ key: String, _ arguments: CVarArg...) -> String {
        let format = String(localized: String.LocalizationValue(key))
        return String(format: format, locale: .current, arguments: arguments)
    }

    static func suffix(for tool: Tool) -> String {
        t(tool.suffixKey)
    }

    static func languageName(for code: String) -> String {
        if code == "system" { return t("settings.language.system") }
        let locale = Locale(identifier: code)
        return locale.localizedString(forIdentifier: code) ?? code
    }
}

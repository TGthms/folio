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

    private final class Generation: @unchecked Sendable {
        var value = 0
    }

    private static let generationBox = Generation()

    static var generation: Int { generationBox.value }

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

    /// Maps a BCP-47 / Apple language id onto a shipped catalog code.
    static func resolve(_ raw: String) -> String {
        if supportedCodes.contains(raw) { return raw }
        let folded = raw.replacingOccurrences(of: "_", with: "-")
        if folded.hasPrefix("zh-Hans") || folded.hasPrefix("zh-CN") || folded == "zh" {
            return "zh-Hans"
        }
        if folded.hasPrefix("zh-Hant") || folded.hasPrefix("zh-TW") || folded.hasPrefix("zh-HK") {
            return "zh-Hant"
        }
        if folded.hasPrefix("pt-BR") { return "pt-BR" }
        if folded.hasPrefix("pt") { return "pt-PT" }
        let prefix = folded.split(separator: "-").first.map(String.init) ?? folded
        if supportedCodes.contains(prefix) { return prefix }
        return "en"
    }

    /// Catalog used by every `t(_:)` lookup in the UI.
    static var catalogCode: String {
        if let overrideCode { return resolve(overrideCode) }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return resolve(preferred)
    }

    @discardableResult
    static func apply(_ code: String?) -> String {
        overrideCode = code
        if let code {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        generationBox.value &+= 1
        return catalogCode
    }

    static func applyOverrideAtLaunch() {
        if let code = overrideCode {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }
    }

    static var effectiveCode: String { catalogCode }

    static var isRTL: Bool {
        rtlCodes.contains(catalogCode)
    }

    /// Looks up `key` in the shipped `.lproj` table for `locale` (not process `AppleLanguages`).
    static func string(_ key: String, locale: String) -> String {
        let code = resolve(locale)
        if let value = tableValue(key, locale: code) {
            return value
        }
        if code != "en", let value = tableValue(key, locale: "en") {
            return value
        }
        return key
    }

    static func t(_ key: String) -> String {
        string(key, locale: catalogCode)
    }

    static func t(_ key: String, _ arguments: CVarArg...) -> String {
        let format = string(key, locale: catalogCode)
        return String(format: format, locale: Locale(identifier: catalogCode), arguments: arguments)
    }

    static func suffix(for tool: Tool) -> String {
        t(tool.suffixKey)
    }

    static func languageName(for code: String) -> String {
        if code == "system" { return t("settings.language.system") }
        let locale = Locale(identifier: catalogCode)
        return locale.localizedString(forIdentifier: code) ?? code
    }

    private static func tableValue(_ key: String, locale: String) -> String? {
        guard
            let url = Bundle.main.url(
                forResource: "Localizable",
                withExtension: "strings",
                subdirectory: nil,
                localization: locale
            ),
            let table = NSDictionary(contentsOf: url) as? [String: String],
            let value = table[key],
            !value.isEmpty
        else {
            return nil
        }
        return value
    }
}

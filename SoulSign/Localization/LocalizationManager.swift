//
//  LocalizationManager.swift
//  SoulSign
//
import Foundation

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    private let storageKey = "soulsign_language_v1"

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: storageKey) }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           let lang = AppLanguage(rawValue: saved) {
            self.language = lang
        } else {
            let preferred = Locale.preferredLanguages.first.flatMap { String($0.prefix(2)) } ?? "en"
            self.language = AppLanguage(rawValue: preferred) ?? .en
        }
    }

    /// Look up a translated string for the current language, falling back to English.
    func t(_ key: String) -> String {
        Translations.table[language]?[key] ?? Translations.table[.en]?[key] ?? key
    }

    /// Format a translated string containing one %@ placeholder.
    func t(_ key: String, _ arg: String) -> String {
        String(format: t(key), arg)
    }
}

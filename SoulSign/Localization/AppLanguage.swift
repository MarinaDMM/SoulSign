//
//  AppLanguage.swift
//  SoulSign
//
import Foundation

enum AppLanguage: String, CaseIterable, Codable {
    case en, nl, fr, de, es, it, ru, uk, pl

    /// Short code shown in the language picker (Ukrainian uses "UA" by request, not ISO "UK").
    var shortCode: String {
        switch self {
        case .en: return "EN"
        case .nl: return "NL"
        case .fr: return "FR"
        case .de: return "DE"
        case .es: return "ES"
        case .it: return "IT"
        case .ru: return "RU"
        case .uk: return "UA"
        case .pl: return "PL"
        }
    }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .nl: return "Nederlands"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .es: return "Español"
        case .it: return "Italiano"
        case .ru: return "Русский"
        case .uk: return "Українська"
        case .pl: return "Polski"
        }
    }

    /// English name of the language, used to instruct Claude what language to write in.
    var englishName: String {
        switch self {
        case .en: return "English"
        case .nl: return "Dutch"
        case .fr: return "French"
        case .de: return "German"
        case .es: return "Spanish"
        case .it: return "Italian"
        case .ru: return "Russian"
        case .uk: return "Ukrainian"
        case .pl: return "Polish"
        }
    }

    var locale: Locale { Locale(identifier: rawValue) }
}

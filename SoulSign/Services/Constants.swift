//
//  Constants.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//
import Foundation

struct Constants {
    static let anthropicAPIKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String ?? ""
}

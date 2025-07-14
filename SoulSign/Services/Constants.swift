//
//  Constants.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//
import Foundation

struct Constants {
    static let openAIAPIKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
    static let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
}

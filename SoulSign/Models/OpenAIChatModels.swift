//
//  OpenAIChatModels.swift
//  SoulSign
//
//  Created by Marina Dedikova on 17/07/2025.
//
import Foundation

enum OpenAIModels {
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }

    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
    }
}

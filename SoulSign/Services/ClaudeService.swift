//
//  ClaudeService.swift
//  SoulSign
//

import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

final class ClaudeService {
    private let endpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-opus-4-8"
    private let session: URLSession

    /// Session is injectable so tests can supply a mocked URLSession.
    init(session: URLSession = .shared) {
        self.session = session
    }

    func send(messages: [ChatMessage]) async throws -> String {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Constants.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let raw = String(data: data, encoding: .utf8) ?? "unknown error"
            throw NSError(domain: "ClaudeAPI", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: raw])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            let raw = String(data: data, encoding: .utf8) ?? "empty"
            throw NSError(domain: "ClaudeAPI", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unexpected response: \(raw)"])
        }
        return text
    }
}

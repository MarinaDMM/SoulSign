//
//  AffirmationService.swift
//  SoulSign
//
//  Created by Marina Dedikova on 16/07/2025.
import Foundation

struct AffirmationResponse: Codable {
    let Finance: String
    let Love: String
    let MindSpirit: String
    let Career: String
    let Friendship: String
    let Health: String
}

class AffirmationService {
    private static let cacheKey = "todaysAffirmation"
    private static let cacheDateKey = "todaysAffirmationDate"
    private static let cacheLangKey = "todaysAffirmationLang"
    private static let cacheKindKey = "todaysAffirmationKind"

    /// Overridable so tests can inject a mocked URLSession.
    static var session: URLSession = .shared

    /// Cache kind: general affirmations, or ones written to "you".
    private static func kind(forYou: Bool) -> String { forYou ? "you" : "general" }

    static func fetchAndStoreAffirmations(language: AppLanguage, forYou: Bool = false,
                                          completion: @escaping (AffirmationResponse?) -> Void) {
        fetchAffirmations(language: language, forYou: forYou) { result in
            if let result = result {
                if let data = try? JSONEncoder().encode(result) {
                    UserDefaults.standard.set(data, forKey: cacheKey)
                    UserDefaults.standard.set(currentDateString(), forKey: cacheDateKey)
                    UserDefaults.standard.set(language.rawValue, forKey: cacheLangKey)
                    UserDefaults.standard.set(kind(forYou: forYou), forKey: cacheKindKey)
                }
            }
            completion(result)
        }
    }

    static func loadStoredAffirmations(language: AppLanguage, forYou: Bool = false) -> AffirmationResponse? {
        guard let cachedDate = UserDefaults.standard.string(forKey: cacheDateKey),
              cachedDate == currentDateString(),
              UserDefaults.standard.string(forKey: cacheLangKey) == language.rawValue,
              UserDefaults.standard.string(forKey: cacheKindKey) == kind(forYou: forYou),
              let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(AffirmationResponse.self, from: data) else {
            return nil
        }
        return decoded
    }

    /// The prompt sent to Claude. Contains only an instruction and the language:
    /// never a name, a chart, or any note the user has written.
    static func buildPrompt(language: AppLanguage, forYou: Bool) -> String {
        let languageLine = language == .en ? "" : " Write every affirmation in \(language.englishName)."
        let voiceLine = forYou
            ? " Write each affirmation directly to the reader as \"you\", in the second person, warm and personal."
            : ""
        return """
Generate daily affirmations in JSON format with exactly these keys: Finance, Love, MindSpirit, Career, Friendship, and Health.\(languageLine)\(voiceLine)
Return ONLY raw JSON without any explanation, markdown, or formatting. Example:

{
  "Finance": "...",
  "Love": "...",
  "MindSpirit": "...",
  "Career": "...",
  "Friendship": "...",
  "Health": "..."
}
"""
    }

    static func fetchAffirmations(language: AppLanguage, forYou: Bool = false,
                                  completion: @escaping (AffirmationResponse?) -> Void) {
        let apiKey = Constants.anthropicAPIKey
        if apiKey.isEmpty {
            print("❌ ANTHROPIC_API_KEY is missing or empty")
            completion(nil)
            return
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!

        let body: [String: Any] = [
            "model": "claude-opus-4-8",
            "max_tokens": 512,
            "system": "You are an encouraging and creative life coach.",
            "messages": [
                [
                    "role": "user",
                    "content": buildPrompt(language: language, forYou: forYou)
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let data = data else {
                print("❌ No data received from Claude")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                print("🧾 Raw Claude response:\n\(raw)")
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let content = json["content"] as? [[String: Any]],
                let text = content.first?["text"] as? String
            else {
                print("❌ Failed to extract 'text' from Claude response")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            print("🔎 Claude content:\n\(text)")

            guard let jsonData = text.data(using: .utf8),
                  let affirmations = try? JSONDecoder().decode(AffirmationResponse.self, from: jsonData) else {
                print("❌ Failed to decode content into AffirmationResponse")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            DispatchQueue.main.async {
                completion(affirmations)
            }
        }.resume()
    }

    private static func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

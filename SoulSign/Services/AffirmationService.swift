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

    static func fetchAndStoreAffirmations(language: AppLanguage, completion: @escaping (AffirmationResponse?) -> Void) {
        fetchAffirmations(language: language) { result in
            if let result = result {
                if let data = try? JSONEncoder().encode(result) {
                    UserDefaults.standard.set(data, forKey: cacheKey)
                    UserDefaults.standard.set(currentDateString(), forKey: cacheDateKey)
                    UserDefaults.standard.set(language.rawValue, forKey: cacheLangKey)
                }
            }
            completion(result)
        }
    }

    static func loadStoredAffirmations(language: AppLanguage) -> AffirmationResponse? {
        guard let cachedDate = UserDefaults.standard.string(forKey: cacheDateKey),
              cachedDate == currentDateString(),
              UserDefaults.standard.string(forKey: cacheLangKey) == language.rawValue,
              let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(AffirmationResponse.self, from: data) else {
            return nil
        }
        return decoded
    }

    static func fetchAffirmations(language: AppLanguage, completion: @escaping (AffirmationResponse?) -> Void) {
        let apiKey = Constants.anthropicAPIKey
        if apiKey.isEmpty {
            print("❌ ANTHROPIC_API_KEY is missing or empty")
            completion(nil)
            return
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!

        let languageLine = language == .en ? "" : " Write every affirmation in \(language.englishName)."

        let body: [String: Any] = [
            "model": "claude-opus-4-8",
            "max_tokens": 512,
            "system": "You are an encouraging and creative life coach.",
            "messages": [
                [
                    "role": "user",
                    "content": """
Generate daily affirmations in JSON format with exactly these keys: Finance, Love, MindSpirit, Career, Friendship, and Health.\(languageLine)
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
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
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

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

    static func fetchAndStoreAffirmations(completion: @escaping (AffirmationResponse?) -> Void) {
        fetchAffirmations { result in
            if let result = result {
                if let data = try? JSONEncoder().encode(result) {
                    UserDefaults.standard.set(data, forKey: cacheKey)
                    UserDefaults.standard.set(currentDateString(), forKey: cacheDateKey)
                }
            }
            completion(result)
        }
    }

    static func loadStoredAffirmations() -> AffirmationResponse? {
        guard let cachedDate = UserDefaults.standard.string(forKey: cacheDateKey),
              cachedDate == currentDateString(),
              let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode(AffirmationResponse.self, from: data) else {
            return nil
        }

        return decoded
    }

    static func fetchAffirmations(completion: @escaping (AffirmationResponse?) -> Void) {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
        if apiKey.isEmpty {
            print("❌ OPENAI_API_KEY is missing or empty")
            completion(nil)
            return
        } else {
            print("✅ OPENAI_API_KEY loaded")
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]

        let messages: [OpenAIModels.ChatMessage] = [
            OpenAIModels.ChatMessage(role: "system", content: "You are an encouraging and creative life coach."),
            OpenAIModels.ChatMessage(role: "user", content: """
Generate daily affirmations in JSON format with exactly these keys: Finance, Love, MindSpirit, Career, Friendship, and Health. 
Return ONLY raw JSON without any explanation, markdown, or formatting. Example:

{
  "Finance": "...",
  "Love": "...",
  "MindSpirit": "...",
  "Career": "...",
  "Friendship": "...",
  "Health": "..."
}
""")
        ]

        let body = OpenAIModels.ChatRequest(
            model: "gpt-3.5-turbo",
            messages: messages,
            temperature: 0.9
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let data = data else {
                print("❌ No data received from OpenAI")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                print("🧾 Raw OpenAI response:\n\(raw)")
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let choices = json["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let content = message["content"] as? String
            else {
                print("❌ Failed to extract 'content' from OpenAI response")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            print("🔎 GPT content:\n\(content)")

            guard let jsonData = content.data(using: .utf8),
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


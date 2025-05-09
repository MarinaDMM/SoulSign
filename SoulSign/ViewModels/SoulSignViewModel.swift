//
//  SoulSignViewModel.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import Foundation

@MainActor
final class SoulsignViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var chartResult: String = ""
    @Published var errorMessage: String?

    private let openAIService = OpenAIService()

    func generateChart(fullName: String, birthDate: Date, birthTime: Date, birthPlace: String) async {
        isLoading = true
        errorMessage = nil

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let dateString = dateFormatter.string(from: birthDate)
        let timeString = timeFormatter.string(from: birthTime)

        let prompt = """
        Create a detailed astrological natal chart analysis for the following person:

        Full Name: \(fullName)
        Date of Birth: \(dateString)
        Time of Birth: \(timeString)
        Place of Birth: \(birthPlace)

        Focus on personality traits, life purpose, challenges, and any important planetary alignments. Write in a friendly and insightful tone.
        """

        let messages = [
            ChatMessage(role: "user", content: prompt)
        ]

        do {
            let response = try await openAIService.send(messages: messages)
            self.chartResult = response
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

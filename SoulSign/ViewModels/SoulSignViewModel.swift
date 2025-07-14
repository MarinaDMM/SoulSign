//
//  SoulSignViewModel.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import Foundation
import CoreLocation

@MainActor
final class SoulSignViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var chartResult: String = ""
    @Published var errorMessage: String?

    private let openAIService = OpenAIService()

    func generateChart(
        fullName: String,
        birthDate: Date,
        birthTime: Date,
        birthPlace: String,
        coordinates: CLLocationCoordinate2D?
    ) async {
        isLoading = true
        errorMessage = nil

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let dateString = dateFormatter.string(from: birthDate)
        let timeString = timeFormatter.string(from: birthTime)

        var coordNote = ""
        if let coord = coordinates {
            coordNote = "\nCoordinates: \(coord.latitude), \(coord.longitude)"
        }

        let prompt = """
        Create a detailed astrological natal chart reading for this person:

        Full Name: \(fullName)
        Date of Birth: \(dateString)
        Time of Birth: \(timeString)
        Place of Birth: \(birthPlace)\(coordNote)

        Focus on personality traits, soul purpose, life path, and any meaningful planetary alignments. Use warm, beginner-friendly language.
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


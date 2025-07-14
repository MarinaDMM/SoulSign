//  BirthPlaceSuggestionView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 07/06/2025.
//
// BirthPlaceSuggestionsView.swift
import SwiftUI
import GooglePlaces

struct BirthPlaceSuggestionsView: View {
    @ObservedObject var placeVM: PlaceSearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("City, Country", text: $placeVM.searchText)
                .foregroundColor(.black)
                .autocapitalization(.words)
                .padding(10)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .multilineTextAlignment(.leading)

            if !placeVM.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(placeVM.suggestions, id: \ .placeID) { prediction in
                        Button(action: {
                            let selectedText = prediction.attributedFullText.string
                            placeVM.searchText = selectedText
                            placeVM.selectedPlaceName = selectedText
                            placeVM.suggestions = []
                            placeVM.fetchCoordinates(for: prediction)
                        }) {
                            Text(prediction.attributedFullText.string)
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
            }
        }
    }
}

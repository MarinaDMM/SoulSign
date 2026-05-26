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
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("City, Country", text: $placeVM.searchText)
                .foregroundColor(theme.fieldText)
                .autocapitalization(.words)
                .padding(10)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(theme.primaryText.opacity(0.3), lineWidth: 1)
                )
                .multilineTextAlignment(.leading)

            if !placeVM.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(placeVM.suggestions, id: \.placeID) { prediction in
                        Button(action: {
                            placeVM.selectPrediction(prediction)
                        }) {
                            Text(prediction.attributedFullText.string)
                                .foregroundColor(theme.suggestionText)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(theme.suggestionRowBg)
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(theme.suggestionListBg)
                .cornerRadius(12)
            }
        }
    }
}

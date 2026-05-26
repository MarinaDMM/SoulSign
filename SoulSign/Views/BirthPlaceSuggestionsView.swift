//  BirthPlaceSuggestionsView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 07/06/2025.
//
import SwiftUI
import GooglePlaces

/// The text field that lives inside the Form cell.
struct BirthPlaceTextField: View {
    @ObservedObject var placeVM: PlaceSearchViewModel
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        TextField("City, Country", text: $placeVM.searchText)
            .foregroundColor(theme.fieldText)
            .autocapitalization(.words)
            .multilineTextAlignment(.leading)
    }
}

/// The dropdown that floats in the ZStack — NOT inside the Form — so
/// UITableView's stale hit-test rects never interfere with tap targets.
struct BirthPlaceSuggestionsDropdown: View {
    @ObservedObject var placeVM: PlaceSearchViewModel
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        if !placeVM.suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(placeVM.suggestions, id: \.placeID) { prediction in
                    Button {
                        placeVM.selectPrediction(prediction)
                    } label: {
                        Text(prediction.attributedFullText.string)
                            .foregroundColor(theme.suggestionText)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    // Explicit tappable area — avoids hit-test ambiguity
                    .contentShape(Rectangle())

                    if prediction.placeID != placeVM.suggestions.last?.placeID {
                        Divider().background(theme.suggestionText.opacity(0.2))
                    }
                }
            }
            .background(theme.suggestionListBg)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
            .padding(.horizontal)
        }
    }
}

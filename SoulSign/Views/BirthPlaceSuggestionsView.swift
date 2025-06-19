//
//  BirthPlaceSuggestionsView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//
import SwiftUI
import GooglePlaces

struct BirthPlaceSuggestionsView: View {
    @ObservedObject var placeVM: PlaceSearchViewModel
    var isDisabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Enter Birth Place", text: $placeVM.searchText)
                .disabled(isDisabled)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 4)

            if placeVM.shouldShowSuggestions && !placeVM.suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(placeVM.suggestions, id: \.placeID) { suggestion in
                        Button(action: {
                            placeVM.selectSuggestion(suggestion)
                        }) {
                            Text(suggestion.attributedFullText.string)
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                    }
                }
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3))
                )
                .shadow(radius: 2)
            }
        }
        .padding(.horizontal)
    }
}

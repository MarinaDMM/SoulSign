//
//  BirthPlaceSuggestionsView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import SwiftUI
import GooglePlaces
import CoreLocation

struct BirthPlaceSuggestionsView: View {
    @ObservedObject var placeVM: PlaceSearchViewModel

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Enter Birth Place", text: $placeVM.searchQuery)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .onChange(of: placeVM.searchQuery) { newValue in
                    placeVM.fetchSuggestions(for: newValue)
                }

            if !placeVM.suggestions.isEmpty && placeVM.shouldShowSuggestions {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(placeVM.suggestions.indices, id: \.self) { index in
                            let suggestion = placeVM.suggestions[index]
                            Text(suggestion.attributedPrimaryText.string)
                                .foregroundColor(.white)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.4))
                                .cornerRadius(6)
                                .onTapGesture {
                                    placeVM.selectSuggestion(suggestion)
                                }
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxHeight: 200)
            }
        }
    }
}

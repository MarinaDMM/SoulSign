//  BirthPlaceSuggestionsView.swift
//  SoulSign
//
import SwiftUI

/// The text field that lives inside the Form's Birth Place section.
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

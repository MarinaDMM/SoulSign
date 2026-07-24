//  BirthPlaceSuggestionsView.swift
//  SoulSign
//
import SwiftUI

/// The text field that lives inside the Form's Birth Place section.
struct BirthPlaceTextField: View {
    @ObservedObject var placeVM: PlaceSearchViewModel
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        TextField(loc.t("field_city_country"), text: $placeVM.searchText)
            .foregroundColor(theme.fieldText)
            .autocapitalization(.words)
            .multilineTextAlignment(.leading)
    }
}

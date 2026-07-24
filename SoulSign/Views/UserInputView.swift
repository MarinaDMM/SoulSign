//
//  UserInputView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//
import SwiftUI
import MapKit
import CoreLocation

struct UserInputView: View {
    @State private var fullName: String = ""
    @State private var birthDate: Date = Date()
    @State private var birthTime: Date = Date()
    @StateObject private var placeVM = PlaceSearchViewModel()
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var onSubmit: (_ fullName: String, _ birthDate: Date, _ birthTime: Date, _ birthPlace: String, _ coordinates: CLLocationCoordinate2D?) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            NightSkyBackground()

            Form {
                Section(header: Text(loc.t("section_personal_info")).foregroundColor(theme.primaryText)) {
                    TextField(loc.t("field_full_name"), text: $fullName)
                        .autocapitalization(.words)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(theme.fieldText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section(header: Text(loc.t("section_birth_date")).foregroundColor(theme.primaryText)) {
                    DatePicker(loc.t("field_select_date"), selection: $birthDate, displayedComponents: .date)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section(header: Text(loc.t("section_birth_time")).foregroundColor(theme.primaryText)) {
                    DatePicker(loc.t("field_select_time"), selection: $birthTime, displayedComponents: .hourAndMinute)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section(header: Text(loc.t("section_birth_place")).foregroundColor(theme.primaryText)) {
                    BirthPlaceTextField(placeVM: placeVM)

                    ForEach(placeVM.suggestions, id: \.self) { suggestion in
                        Button {
                            placeVM.selectSuggestion(suggestion)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .foregroundColor(theme.fieldText)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(theme.fieldText.opacity(0.6))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Button(loc.t("button_add_person")) {
                        onSubmit(
                            fullName,
                            birthDate,
                            birthTime,
                            placeVM.selectedPlaceName,
                            placeVM.selectedCoordinates
                        )
                    }
                    .disabled(fullName.isEmpty || placeVM.selectedPlaceName.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .environment(\.locale, loc.language.locale)
        }
        .navigationTitle(loc.t("nav_new_person"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(theme.navColorScheme, for: .navigationBar)
    }
}

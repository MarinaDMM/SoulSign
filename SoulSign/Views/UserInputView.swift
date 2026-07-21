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
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var onSubmit: (_ fullName: String, _ birthDate: Date, _ birthTime: Date, _ birthPlace: String, _ coordinates: CLLocationCoordinate2D?) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            NightSkyBackground()

            Form {
                Section(header: Text("Personal Info").foregroundColor(theme.primaryText)) {
                    TextField("Full Name", text: $fullName)
                        .autocapitalization(.words)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(theme.fieldText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section(header: Text("Birth Date").foregroundColor(theme.primaryText)) {
                    DatePicker("Select Date", selection: $birthDate, displayedComponents: .date)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section(header: Text("Birth Time").foregroundColor(theme.primaryText)) {
                    DatePicker("Select Time", selection: $birthTime, displayedComponents: .hourAndMinute)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section(header: Text("Birth Place").foregroundColor(theme.primaryText)) {
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
                    Button("Add Person ✨") {
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
            .environment(\.locale, Locale(identifier: "en_US"))
        }
        .navigationTitle("New Person")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(theme.navColorScheme, for: .navigationBar)
    }
}

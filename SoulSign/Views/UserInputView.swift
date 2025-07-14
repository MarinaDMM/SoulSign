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

    var onSubmit: (_ fullName: String, _ birthDate: Date, _ birthTime: Date, _ birthPlace: String, _ coordinates: CLLocationCoordinate2D?) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                NightSkyBackground()

                Form {
                    Section(header: Text("Personal Info").foregroundColor(.white)) {
                        TextField("Full Name", text: $fullName)
                            .autocapitalization(.words)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.black)
                            .accentColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Section(header: Text("Birth Date").foregroundColor(.white)) {
                        DatePicker("Select Date", selection: $birthDate, displayedComponents: .date)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Section(header: Text("Birth Time").foregroundColor(.white)) {
                        DatePicker("Select Time", selection: $birthTime, displayedComponents: .hourAndMinute)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Section(header: Text("Birth Place").foregroundColor(.white)) {
                        BirthPlaceSuggestionsView(placeVM: placeVM)
                    }

                    Section {
                        Button("Read My Chart ✨") {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    let titleText = Text("Enter Birth Details")
                        .foregroundColor(.white)
                        .font(.largeTitle.weight(.bold))

                    titleText
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading)
                }
            }
        }
    }
}

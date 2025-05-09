//
//  UserInputView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import SwiftUI

struct UserInputView: View {
    @State private var fullName: String = ""
    @State private var birthDate: Date = Date()
    @State private var birthTime: Date = Date()
    @State private var birthPlace: String = ""

    var onSubmit: (_ fullName: String, _ birthDate: Date, _ birthTime: Date, _ birthPlace: String) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("Full Name", text: $fullName)
                }

                Section(header: Text("Birth Date")) {
                    DatePicker("Select Date", selection: $birthDate, displayedComponents: .date)
                }

                Section(header: Text("Birth Time")) {
                    DatePicker("Select Time", selection: $birthTime, displayedComponents: .hourAndMinute)
                }

                Section(header: Text("Birth Place")) {
                    TextField("City, Country", text: $birthPlace)
                }

                Section {
                    Button("Generate Chart") {
                        onSubmit(fullName, birthDate, birthTime, birthPlace)
                    }
                    .disabled(fullName.isEmpty || birthPlace.isEmpty)
                }
            }
            .navigationTitle("Enter Birth Details")
        }
    }
}

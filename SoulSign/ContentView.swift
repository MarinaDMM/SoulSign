//
//  ContentView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SoulsignViewModel()

    var body: some View {
        VStack {
            if viewModel.chartResult.isEmpty {
                UserInputView { fullName, birthDate, birthTime, birthPlace in
                    Task {
                        await viewModel.generateChart(
                            fullName: fullName,
                            birthDate: birthDate,
                            birthTime: birthTime,
                            birthPlace: birthPlace
                        )
                    }
                }
            } else {
                ScrollView {
                    Text(viewModel.chartResult)
                        .padding()
                }
                .navigationTitle("Your Natal Chart")
                .toolbar {
                    Button("Try Again") {
                        viewModel.chartResult = ""
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView("Generating Chart...")
                    .padding()
            }

            if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
        }
    }
}

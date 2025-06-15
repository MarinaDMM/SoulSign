//
//  ContentView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//
import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var viewModel = SoulSignViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                NightSkyBackground()

                if viewModel.chartResult.isEmpty {
                    UserInputView { fullName, birthDate, birthTime, birthPlace, coordinates in
                        Task {
                            await viewModel.generateChart(
                                fullName: fullName,
                                birthDate: birthDate,
                                birthTime: birthTime,
                                birthPlace: birthPlace,
                                coordinates: coordinates
                            )
                        }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("✨ Your SoulSign Reading")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(viewModel.chartResult)
                                .foregroundColor(.white)
                                .font(.body)
                                .multilineTextAlignment(.leading)

                            Button("🔁 Generate Another Chart") {
                                viewModel.chartResult = ""
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.purple)
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                }

                if viewModel.isLoading {
                    VStack {
                        ProgressView("Generating Chart...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                            .padding()
                    }
                }

                if let error = viewModel.errorMessage {
                    Text("⚠️ \(error)")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("SoulSign")
        }
    }
}

//
//  WelcomeView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import SwiftUI
//import MapKit
//import Combine

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        ZStack {
            NightSkyBackground()
            LottieView(filename: "sparkles")
                .ignoresSafeArea()
                .opacity(0.3)

            VStack(spacing: 30) {
                Spacer()

                Image("soulsign_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)

                Text("🌌 Welcome to SoulSign")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Discover your cosmic blueprint.\nExplore your soul's story through the stars.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Button {
                    hasSeenWelcome = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(.purple)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
    }
}

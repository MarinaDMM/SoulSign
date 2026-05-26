//
//  WelcomeView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            NightSkyBackground()

            // Extra sparkle layer on welcome screen
            LottieView(filename: "sparkles")
                .ignoresSafeArea()
                .opacity(theme.sparkleOpacity)

            VStack(spacing: 30) {
                Spacer()

                Image("soulsign_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)

                Text("🌌 Welcome to SoulSign")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)

                Text("Discover your cosmic blueprint.\nExplore your soul's story through the stars.")
                    .font(.title3)
                    .foregroundColor(theme.secondaryText)
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
                        .background(theme.primaryButtonBg)
                        .foregroundColor(theme.primaryButtonText)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
    }
}

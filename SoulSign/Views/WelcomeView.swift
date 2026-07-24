//
//  WelcomeView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @EnvironmentObject var loc: LocalizationManager
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

                Text(loc.t("welcome_title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)

                Text(loc.t("welcome_subtitle"))
                    .font(.title3)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Button {
                    hasSeenWelcome = true
                } label: {
                    Text(loc.t("button_get_started"))
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

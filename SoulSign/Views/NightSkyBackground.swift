//
//  NightSkyBackground.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import SwiftUI

struct NightSkyBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = AppTheme(colorScheme: colorScheme)
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: theme.backgroundColors),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LottieView(filename: "sparkles")
                .ignoresSafeArea()
                .opacity(theme.sparkleOpacity)
        }
    }
}

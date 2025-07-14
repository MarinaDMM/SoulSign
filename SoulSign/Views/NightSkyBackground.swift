//
//  NightSkyBackground.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import SwiftUI

struct NightSkyBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.6), Color.purple]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            LottieView(filename: "sparkles")
                .ignoresSafeArea()
                .opacity(0.3)
        }
    }
}

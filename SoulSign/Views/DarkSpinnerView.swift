//
//  DarkSpinnerView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 15/06/2025.
//
import SwiftUI

struct DarkSpinnerView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5).opacity(0.9))
                .frame(width: 80, height: 80)
                .shadow(radius: 10)

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                .scaleEffect(2.0)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1.0)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

//
//  PartnerChartView.swift
//  SoulSign
//
import SwiftUI

struct PartnerChartView: View {
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            NightSkyBackground()
            VStack(spacing: 24) {
                Text("💑")
                    .font(.system(size: 80))
                    .shadow(color: .pink.opacity(0.5), radius: 20)
                Text(loc.t("partner_chart"))
                    .font(.title.bold())
                    .foregroundColor(theme.primaryText)
                Text(loc.t("partner_chart_body"))
                    .font(.body)
                    .foregroundColor(theme.primaryText.opacity(0.60))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .navigationTitle(loc.t("partner_chart"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

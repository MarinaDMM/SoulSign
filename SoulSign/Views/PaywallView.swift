//
//  PaywallView.swift
//  SoulSign
//
//  Apple requires a paywall to clearly show what's being sold, the price,
//  the billing period, a Restore Purchases action, and links to Terms and
//  the Privacy Policy. All of that lives here.
//
import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subs: SubscriptionManager
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var selected: PlusProduct = .yearly
    @State private var isPurchasing = false

    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://marinadmm.github.io/SoulSign/privacy.html")!

    var body: some View {
        ZStack {
            NightSkyBackground()

            ScrollView {
                VStack(spacing: 22) {
                    header
                    benefits
                    planOptions
                    subscribeButton
                    legalFooter
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(loc.t("plus_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(loc.t("button_close")) { dismiss() }
                    .foregroundColor(theme.primaryText)
            }
        }
        .task {
            await subs.loadProducts()
            await subs.refreshEntitlement()
        }
        .onChange(of: subs.isPlus) { nowPlus in
            if nowPlus { dismiss() }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 10) {
            Text("✨")
                .font(.system(size: 54))
                .shadow(color: .yellow.opacity(0.45), radius: 18)
            Text(loc.t("plus_title"))
                .font(.title.bold())
                .foregroundColor(theme.primaryText)
            Text(loc.t("plus_subtitle"))
                .font(.subheadline)
                .foregroundColor(theme.primaryText.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 6)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefitRow("💑", loc.t("plus_benefit_partner"))
            benefitRow("👥", loc.t("plus_benefit_people", "\(FreeTier.maxSavedPeople)"))
            benefitRow("🃏", loc.t("plus_benefit_tarot"))
            benefitRow("🌟", loc.t("plus_benefit_readings"))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.12), lineWidth: 1))
    }

    private func benefitRow(_ emoji: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji).font(.system(size: 20))
            Text(text)
                .font(.subheadline)
                .foregroundColor(theme.primaryText.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var planOptions: some View {
        if subs.isLoadingProducts {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .padding(.vertical, 20)
        } else if subs.products.isEmpty {
            Text(loc.t("plus_unavailable"))
                .font(.footnote)
                .foregroundColor(theme.primaryText.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
        } else {
            VStack(spacing: 12) {
                if let yearly = subs.yearly {
                    planCard(
                        product: yearly,
                        plan: .yearly,
                        periodLabel: loc.t("plus_per_year"),
                        badge: subs.yearlySavingsPercent.map { loc.t("plus_save_percent", "\($0)") }
                    )
                }
                if let monthly = subs.monthly {
                    planCard(
                        product: monthly,
                        plan: .monthly,
                        periodLabel: loc.t("plus_per_month"),
                        badge: nil
                    )
                }
            }
        }
    }

    private func planCard(product: Product, plan: PlusProduct, periodLabel: String, badge: String?) -> some View {
        let isSelected = selected == plan
        return Button {
            selected = plan
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(product.displayPrice)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)
                        Text(periodLabel)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    if let badge {
                        Text(badge)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color(hue: 0.12, saturation: 0.9, brightness: 0.95))
                    }
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? .white.opacity(0.14) : .white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? .white.opacity(0.55) : .white.opacity(0.14), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }

    private var subscribeButton: some View {
        VStack(spacing: 10) {
            Button {
                Task { await buy() }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: theme.primaryButtonText))
                    } else {
                        Text(loc.t("plus_subscribe"))
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(subs.products.isEmpty ? theme.primaryButtonBg.opacity(0.35) : theme.primaryButtonBg)
                .foregroundColor(theme.primaryButtonText)
                .cornerRadius(12)
            }
            .disabled(subs.products.isEmpty || isPurchasing)

            Button(loc.t("plus_restore")) {
                Task { await subs.restore() }
            }
            .font(.subheadline)
            .foregroundColor(theme.primaryText.opacity(0.75))

            if let error = subs.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var legalFooter: some View {
        VStack(spacing: 10) {
            Text(loc.t("plus_renewal_disclosure"))
                .font(.caption2)
                .foregroundColor(theme.primaryText.opacity(0.5))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 18) {
                Link(loc.t("plus_terms"), destination: termsURL)
                Link(loc.t("plus_privacy"), destination: privacyURL)
            }
            .font(.caption2)
            .foregroundColor(theme.primaryText.opacity(0.65))
        }
        .padding(.top, 4)
        .padding(.bottom, 20)
    }

    private func buy() async {
        guard let product = selected == .yearly ? subs.yearly : subs.monthly else { return }
        isPurchasing = true
        await subs.purchase(product)
        isPurchasing = false
    }
}

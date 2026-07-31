//
//  PartnerChartView.swift
//  SoulSign
//
import SwiftUI

struct PartnerChartView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var personA: UserProfile?
    @State private var personB: UserProfile?
    @State private var pickingSlot: Slot?
    @State private var showReading = false

    private enum Slot: Identifiable {
        case a, b
        var id: Int { self == .a ? 0 : 1 }
    }

    private var canRead: Bool { personA != nil && personB != nil }

    var body: some View {
        ZStack {
            NightSkyBackground()

            ScrollView {
                VStack(spacing: 22) {
                    Text("💑")
                        .font(.system(size: 60))
                        .shadow(color: .pink.opacity(0.5), radius: 18)
                        .padding(.top, 8)

                    Text(loc.t("partner_intro"))
                        .font(.subheadline)
                        .foregroundColor(theme.primaryText.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    HStack(alignment: .top, spacing: 14) {
                        slotCard(person: personA, label: loc.t("partner_person_one")) {
                            pickingSlot = .a
                        }
                        slotCard(person: personB, label: loc.t("partner_person_two")) {
                            pickingSlot = .b
                        }
                    }
                    .padding(.horizontal, 20)

                    Button {
                        showReading = true
                    } label: {
                        Text(loc.t("button_read_together"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canRead ? theme.primaryButtonBg : theme.primaryButtonBg.opacity(0.35))
                            .foregroundColor(theme.primaryButtonText)
                            .cornerRadius(12)
                    }
                    .disabled(!canRead)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    if !canRead {
                        Text(loc.t("partner_pick_two_hint"))
                            .font(.caption)
                            .foregroundColor(theme.primaryText.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .navigationTitle(loc.t("partner_chart"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $pickingSlot) { slot in
            PersonPickerView(
                excluding: excluded(for: slot),
                onPick: { picked in
                    switch slot {
                    case .a: personA = picked
                    case .b: personB = picked
                    }
                }
            )
            .environmentObject(profileStore)
            .environmentObject(loc)
        }
        .navigationDestination(isPresented: $showReading) {
            if let a = personA, let b = personB {
                PartnerChartReadingView(personA: a, personB: b)
            }
        }
    }

    private func excluded(for slot: Slot) -> Set<UUID> {
        // Prevent pairing someone with themselves.
        switch slot {
        case .a: return Set([personB?.id].compactMap { $0 })
        case .b: return Set([personA?.id].compactMap { $0 })
        }
    }

    // MARK: - Slot card

    private func slotCard(person: UserProfile?, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                if let person {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hue: 0.75, saturation: 0.55, brightness: 0.65),
                                     Color(hue: 0.65, saturation: 0.65, brightness: 0.50)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 62, height: 62)
                        .overlay(
                            Text(person.initials)
                                .font(.system(size: 21, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    Text(person.firstName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(loc.t("partner_tap_to_change"))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.45))
                } else {
                    Circle()
                        .strokeBorder(.white.opacity(0.30), lineWidth: 1.5)
                        .background(Circle().fill(.white.opacity(0.07)))
                        .frame(width: 62, height: 62)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white.opacity(0.65))
                        )
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                    Text(loc.t("partner_tap_to_choose"))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hue: 0.95, saturation: 0.45, brightness: 0.32).opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

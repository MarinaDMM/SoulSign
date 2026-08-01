//
//  PersonPickerView.swift
//  SoulSign
//
//  Sheet for choosing one person: either an already-saved profile, or a
//  newly entered one (which is also saved to the People list).
//
import SwiftUI
import CoreLocation

struct PersonPickerView: View {
    /// Profiles to hide (e.g. the person already chosen in the other slot).
    var excluding: Set<UUID> = []
    let onPick: (UserProfile) -> Void

    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var showingNewPerson = false

    private var available: [UserProfile] {
        profileStore.profiles.filter { !excluding.contains($0.id) }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = loc.language.locale
        return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NightSkyBackground()

                if available.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(available) { profile in
                            Button {
                                onPick(profile)
                                dismiss()
                            } label: {
                                row(profile)
                            }
                            .listRowBackground(Color.white.opacity(0.07))
                            .listRowSeparatorTint(.white.opacity(0.12))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(loc.t("choose_person"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(loc.t("button_cancel")) { dismiss() }
                        .foregroundColor(theme.primaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewPerson = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(theme.primaryText)
                    }
                }
            }
            .navigationDestination(isPresented: $showingNewPerson) {
                UserInputView { fullName, birthDate, birthTime, birthPlace, coords in
                    let p = UserProfile(
                        name: fullName, birthDate: birthDate, birthTime: birthTime,
                        birthPlace: birthPlace,
                        latitude: coords?.latitude, longitude: coords?.longitude
                    )
                    // Newly entered people join the People list too, so they're
                    // reusable for natal charts and future pairings.
                    profileStore.add(p)
                    onPick(p)
                    dismiss()
                }
            }
        }
    }

    private func row(_ profile: UserProfile) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hue: 0.75, saturation: 0.55, brightness: 0.65),
                             Color(hue: 0.65, saturation: 0.65, brightness: 0.50)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(profile.initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                Text(dateFormatter.string(from: profile.birthDate) + "  ·  " + profile.birthPlace)
                    .font(.caption)
                    .foregroundColor(theme.primaryText.opacity(0.50))
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    /// Distinguishes "you've never added anyone" from "everyone you've
    /// saved is already picked in the other slot" — those need different
    /// copy, since the second case with the old shared "No charts yet"
    /// text incorrectly implied nothing had been saved.
    private var emptyState: some View {
        let allPeopleTakenElsewhere = !profileStore.profiles.isEmpty
        return VStack(spacing: 20) {
            Text("🌌").font(.system(size: 56))
            Text(loc.t(allPeopleTakenElsewhere ? "empty_all_picked_title" : "empty_no_charts"))
                .font(.title3.bold())
                .foregroundColor(theme.primaryText)
            Text(loc.t(allPeopleTakenElsewhere ? "empty_all_picked_body" : "empty_add_someone"))
                .font(.subheadline)
                .foregroundColor(theme.primaryText.opacity(0.6))
                .multilineTextAlignment(.center)
            Button(loc.t(allPeopleTakenElsewhere ? "button_add_another_person" : "button_add_first_person")) {
                showingNewPerson = true
            }
            .padding(.horizontal, 28).padding(.vertical, 12)
            .background(theme.primaryButtonBg)
            .foregroundColor(theme.primaryButtonText)
            .cornerRadius(12)
        }
        .padding()
    }
}

//
//  ProfileListView.swift
//  SoulSign
//
import SwiftUI

struct ProfileListView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = loc.language.locale
        return f
    }

    var body: some View {
        ZStack {
            NightSkyBackground()

            if profileStore.profiles.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(profileStore.profiles) { profile in
                        Button {
                            path.append(AppDestination.natalChart(profile))
                        } label: {
                            ProfileRow(profile: profile, dateFormatter: dateFormatter)
                        }
                        .listRowBackground(Color.white.opacity(0.07))
                        .listRowSeparatorTint(.white.opacity(0.12))
                    }
                    .onDelete { profileStore.remove(at: $0) }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(loc.t("nav_people"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    path.append(AppDestination.newProfile)
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(theme.primaryText)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("🌌").font(.system(size: 64))
            Text(loc.t("empty_no_charts"))
                .font(.title2.bold())
                .foregroundColor(theme.primaryText)
            Text(loc.t("empty_add_someone"))
                .font(.subheadline)
                .foregroundColor(theme.primaryText.opacity(0.6))
                .multilineTextAlignment(.center)
            Button(loc.t("button_add_first_person")) {
                path.append(AppDestination.newProfile)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(theme.primaryButtonBg)
            .foregroundColor(theme.primaryButtonText)
            .cornerRadius(12)
        }
        .padding()
    }
}

private struct ProfileRow: View {
    let profile: UserProfile
    let dateFormatter: DateFormatter
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hue: 0.75, saturation: 0.55, brightness: 0.65),
                             Color(hue: 0.65, saturation: 0.65, brightness: 0.50)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 46, height: 46)
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

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.primaryText.opacity(0.25))
        }
        .padding(.vertical, 4)
    }
}

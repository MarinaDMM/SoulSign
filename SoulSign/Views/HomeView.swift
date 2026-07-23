//
//  HomeView.swift
//  SoulSign
//
import SwiftUI
import UserNotifications

// Navigation destinations for the whole app
enum AppDestination: Hashable {
    case profileList
    case natalChart(UserProfile)
    case newProfile
    case tarot
    case partnerChart
    case affirmations
}

struct HomeView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var notificationRouter: NotificationRouter
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                NightSkyBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SoulSign")
                                .font(.largeTitle.bold())
                                .foregroundColor(theme.primaryText)
                            Text("What calls to you today?")
                                .font(.subheadline)
                                .foregroundColor(theme.primaryText.opacity(0.55))
                        }

                        // Saved profiles row
                        if !profileStore.profiles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader("Your People")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 14) {
                                        ForEach(profileStore.profiles) { profile in
                                            Button {
                                                path.append(AppDestination.natalChart(profile))
                                            } label: {
                                                ProfileChip(profile: profile)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        Button {
                                            path.append(AppDestination.newProfile)
                                        } label: {
                                            AddChip()
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                        }

                        // Feature tiles
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Explore")
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 14
                            ) {
                                FeatureTile(.emoji("🌟"), "Natal Chart",   "Your stars at birth",        hue: 0.12) {
                                    path.append(AppDestination.profileList)
                                }
                                FeatureTile(.image("tarot_major_fool"), "Tarot Today", "Card of the day", hue: 0.78) {
                                    path.append(AppDestination.tarot)
                                }
                                FeatureTile(.emoji("💑"), "Partner Chart", "Cosmic compatibility",        hue: 0.95) {
                                    path.append(AppDestination.partnerChart)
                                }
                                FeatureTile(.emoji("🌞"), "Affirmations",  "Set your daily intention",   hue: 0.55) {
                                    path.append(AppDestination.affirmations)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            // ── Navigation destinations ──────────────────────────────────────
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .profileList:
                    ProfileListView(path: $path)

                case .natalChart(let profile):
                    NatalChartReadingView(profile: profile)

                case .newProfile:
                    UserInputView { fullName, birthDate, birthTime, birthPlace, coords in
                        let p = UserProfile(
                            name: fullName, birthDate: birthDate, birthTime: birthTime,
                            birthPlace: birthPlace,
                            latitude: coords?.latitude, longitude: coords?.longitude
                        )
                        profileStore.add(p)
                        // Replace the newProfile entry in the stack with the reading
                        path.removeLast()
                        path.append(AppDestination.natalChart(p))
                    }

                case .tarot:
                    TarotCardView()

                case .partnerChart:
                    PartnerChartView()

                case .affirmations:
                    DailyAffirmationView()
                }
            }
            .onAppear {
                requestNotificationPermission()
                scheduleDailyAffirmationNotification()
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveNotificationResponse)) { _ in
                DispatchQueue.main.async {
                    path.append(AppDestination.affirmations)
                    notificationRouter.navigateToAffirmations = false
                }
            }
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func scheduleDailyAffirmationNotification() {
        AffirmationService.fetchAffirmations { affirmations in
            guard let a = affirmations else { return }
            let body = [a.Finance, a.Love, a.MindSpirit, a.Career, a.Friendship, a.Health]
                .randomElement() ?? "You are amazing."
            let content = UNMutableNotificationContent()
            content.title = "🌟 Daily Affirmation"
            content.body  = body
            content.sound = .default
            var dc = DateComponents(); dc.hour = 10; dc.minute = 0
            let req = UNNotificationRequest(
                identifier: "daily_affirmation",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            )
            UNUserNotificationCenter.current().add(req) { _ in }
        }
    }
}

// MARK: - Sub-views

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white.opacity(0.75))
    }
}

struct ProfileChip: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hue: 0.75, saturation: 0.55, brightness: 0.65),
                             Color(hue: 0.65, saturation: 0.65, brightness: 0.50)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 54, height: 54)
                .overlay(
                    Text(profile.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: .purple.opacity(0.35), radius: 4, y: 2)
            Text(profile.firstName)
                .font(.caption)
                .foregroundColor(.white.opacity(0.80))
                .lineLimit(1)
        }
        .frame(width: 64)
    }
}

private struct AddChip: View {
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(.white.opacity(0.30), lineWidth: 1.5)
                .background(Circle().fill(.white.opacity(0.07)))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                )
            Text("Add")
                .font(.caption)
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(width: 64)
    }
}

private enum FeatureIcon {
    case emoji(String)
    case image(String)
}

private struct FeatureTile: View {
    let icon: FeatureIcon
    let title: String
    let subtitle: String
    let hue: Double
    let action: () -> Void

    init(_ icon: FeatureIcon, _ title: String, _ subtitle: String, hue: Double, action: @escaping () -> Void) {
        self.icon = icon; self.title = title; self.subtitle = subtitle
        self.hue = hue; self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                iconView
                Spacer()
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.58))
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 128)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hue: hue, saturation: 0.55, brightness: 0.35).opacity(0.70))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .emoji(let e):
            Text(e).font(.system(size: 30))
        case .image(let name):
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 30, height: 30 / (750.0 / 1298.0))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 0.6)
                )
        }
    }
}

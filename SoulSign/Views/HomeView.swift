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
    @EnvironmentObject var loc: LocalizationManager
    @EnvironmentObject var subs: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var path = NavigationPath()
    @State private var showPaywall = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                NightSkyBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SoulSign")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(theme.primaryText)
                                Text(loc.t("app_tagline"))
                                    .font(.subheadline)
                                    .foregroundColor(theme.primaryText.opacity(0.55))
                            }
                            Spacer()
                            LanguagePickerButton()
                                .padding(.top, 6)
                        }

                        // Saved profiles row
                        if !profileStore.profiles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(loc.t("section_your_people"))
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
                                            if subs.isPlus || profileStore.profiles.count < FreeTier.maxSavedPeople {
                                                path.append(AppDestination.newProfile)
                                            } else {
                                                showPaywall = true
                                            }
                                        } label: {
                                            AddChip(locked: !subs.isPlus && profileStore.profiles.count >= FreeTier.maxSavedPeople)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                        }

                        // Feature tiles
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(loc.t("section_explore"))
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 14
                            ) {
                                FeatureTile(.emoji("🌟"), loc.t("natal_chart"), loc.t("subtitle_natal"), hue: 0.12) {
                                    path.append(AppDestination.profileList)
                                }
                                FeatureTile(.image("tarot_major_fool"), loc.t("tarot_today"), loc.t("subtitle_tarot"), hue: 0.78) {
                                    path.append(AppDestination.tarot)
                                }
                                FeatureTile(.emoji("💑"), loc.t("partner_chart"), loc.t("subtitle_partner"),
                                            hue: 0.95, locked: !subs.isPlus) {
                                    if subs.isPlus {
                                        path.append(AppDestination.partnerChart)
                                    } else {
                                        showPaywall = true
                                    }
                                }
                                FeatureTile(.emoji("🌞"), loc.t("affirmations"), loc.t("subtitle_affirmations"), hue: 0.55) {
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
            .sheet(isPresented: $showPaywall) {
                NavigationStack {
                    PaywallView()
                        .environmentObject(subs)
                        .environmentObject(loc)
                }
            }
            .onAppear {
                requestNotificationPermission()
                scheduleDailyAffirmationNotification()
            }
            .onChange(of: loc.language) { _ in
                // The scheduled notification bakes in fixed content at a fixed
                // language; re-schedule (same identifier replaces the pending
                // one) whenever the language changes so it doesn't fire stale.
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
        AffirmationService.fetchAffirmations(language: loc.language) { affirmations in
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
    var locked: Bool = false
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(.white.opacity(0.30), lineWidth: 1.5)
                .background(Circle().fill(.white.opacity(0.07)))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: locked ? "lock.fill" : "plus")
                        .font(.system(size: locked ? 17 : 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                )
            Text(loc.t("add_label"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(width: 64)
    }
}

// MARK: - Language Picker

struct LanguagePickerButton: View {
    @EnvironmentObject var loc: LocalizationManager

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases, id: \.self) { lang in
                Button {
                    loc.language = lang
                } label: {
                    if lang == loc.language {
                        Label(lang.displayName, systemImage: "checkmark")
                    } else {
                        Text(lang.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "globe")
                    .font(.system(size: 13, weight: .medium))
                Text(loc.language.shortCode)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(.white.opacity(0.10))
            )
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.20), lineWidth: 1)
            )
        }
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
    let locked: Bool
    let action: () -> Void

    init(_ icon: FeatureIcon, _ title: String, _ subtitle: String,
         hue: Double, locked: Bool = false, action: @escaping () -> Void) {
        self.icon = icon; self.title = title; self.subtitle = subtitle
        self.hue = hue; self.locked = locked; self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    iconView
                    Spacer()
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
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

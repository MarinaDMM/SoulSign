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
    /// Partner chart, optionally opened with the first person already chosen.
    case partnerChart(UUID?)
    case affirmations
    /// A person's page: their notes first, then their charts.
    case person(UUID)
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

    /// The last seven days' moods, from daily check-ins and from notes about
    /// people. A day with both shows the daily check-in.
    private var weekDays: [(day: Date, mood: Mood?)] {
        var moods: [String: Mood] = [:]
        for (key, entry) in TarotHistoryStore().allSorted() {
            if let mood = entry.mood { moods[key] = mood }
        }
        for profile in profileStore.profiles {
            for note in profile.notes ?? [] {
                guard let mood = note.mood else { continue }
                let key = TarotHistoryStore.dayKey(for: note.date)
                if moods[key] == nil { moods[key] = mood }
            }
        }
        return MoodWeek.build(moodsByDay: moods, today: Date())
    }

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

                        // Today: the card as a writing prompt, then Affirmations
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(loc.t("section_today"))
                            TodayRow(card: TarotDeck.cardForToday(),
                                     title: loc.t("tarot_today"),
                                     subtitle: loc.t("today_prompt")) {
                                path.append(AppDestination.tarot)
                            }
                            HomeRow(emoji: "🌞",
                                    title: loc.t("affirmations"),
                                    subtitle: loc.t("subtitle_affirmations")) {
                                path.append(AppDestination.affirmations)
                            }
                            MoodWeekStrip(days: weekDays)
                        }

                        // People: each person opens their own page
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(loc.t("section_your_people"))
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    ForEach(profileStore.profiles) { profile in
                                        Button {
                                            path.append(AppDestination.person(profile.id))
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
                        // Replace the newProfile entry in the stack with the new person's page
                        path.removeLast()
                        path.append(AppDestination.person(p.id))
                    }

                case .tarot:
                    TarotCardView()

                case .partnerChart(let personID):
                    PartnerChartView(initialPersonAID: personID)

                case .affirmations:
                    DailyAffirmationView()

                case .person(let id):
                    PersonDetailView(profileID: id)
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
        AffirmationService.fetchAffirmations(language: loc.language, forYou: profileStore.me != nil) { affirmations in
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

/// Today's card, shown as a writing prompt. Tapping opens the reading and the journal.
private struct TodayRow: View {
    let card: TarotCard
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                TarotCardFace(card: card)
                    .frame(width: 46)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.62))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hue: 0.78, saturation: 0.55, brightness: 0.35).opacity(0.70))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A single full-width row for secondary features like Affirmations.
private struct HomeRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji).font(.system(size: 26))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.62))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hue: 0.55, saturation: 0.55, brightness: 0.35).opacity(0.70))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ProfileChip: View {
    let profile: UserProfile
    @EnvironmentObject var loc: LocalizationManager

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
            Text(profile.isMe == true ? loc.t("me_badge") : profile.firstName)
                .font(.caption)
                .foregroundColor(.white.opacity(profile.isMe == true ? 0.95 : 0.80))
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

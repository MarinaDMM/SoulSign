//
//  PersonDetailView.swift
//  SoulSign
//
//  A person's page: the notes you've written about them first, then the
//  charts that belong to them. This is the main place a person lives in the
//  app, so the notes lead.
//
import SwiftUI

struct PersonDetailView: View {
    let profileID: UUID

    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var draft = ""
    @State private var moodDraft: Mood?
    @State private var showBreathing = false

    private var profile: UserProfile? {
        profileStore.profiles.first { $0.id == profileID }
    }

    var body: some View {
        ZStack {
            NightSkyBackground()

            if let profile {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header(profile)
                        youSection(profile)
                        notesSection(profile)
                        chartsSection(profile)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(profile?.firstName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBreathing) {
            BreathingPauseView()
                .environmentObject(loc)
        }
    }

    // MARK: - Header

    private func header(_ profile: UserProfile) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(hue: 0.75, saturation: 0.55, brightness: 0.65),
                             Color(hue: 0.65, saturation: 0.65, brightness: 0.50)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(profile.initials)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name)
                    .font(.title3.bold())
                    .foregroundColor(theme.primaryText)
                Text(profile.birthPlace)
                    .font(.caption)
                    .foregroundColor(theme.primaryText.opacity(0.55))
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    // MARK: - You

    /// Marks this person as "you". Only one person can be, so turning this on
    /// for one turns it off for everyone else.
    private func youSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { profile.isMe == true },
                set: { on in profileStore.setMe(on ? profile.id : nil) }
            )) {
                Text(loc.t("me_title"))
                    .foregroundColor(theme.primaryText)
            }
            .tint(.white.opacity(0.6))

            Text(loc.t("me_note"))
                .font(.caption)
                .foregroundColor(theme.primaryText.opacity(0.55))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.07)))
    }

    // MARK: - Notes

    private func notesSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            MoodPicker(selection: $moodDraft)

            Button {
                showBreathing = true
            } label: {
                Label(loc.t("button_breathe"), systemImage: "wind")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.07)))
                    .foregroundColor(theme.primaryText.opacity(0.85))
            }
            .buttonStyle(.plain)

            ReflectionEditor(
                text: $draft,
                titleKey: "person_note_title",
                placeholderKey: "person_note_placeholder",
                saveKey: "button_save_note"
            ) {
                profileStore.addNote(draft, to: profile.id, mood: moodDraft)
                draft = ""
                moodDraft = nil
            }

            Text(loc.t("person_notes_title"))
                .font(.headline)
                .foregroundColor(theme.primaryText)

            let notes = profile.notes ?? []
            if notes.isEmpty {
                Text(loc.t("person_no_notes"))
                    .font(.subheadline)
                    .foregroundColor(theme.primaryText.opacity(0.5))
            } else {
                ForEach(notes) { note in
                    noteRow(note, profileID: profile.id)
                }
            }

            SafetyNote()
        }
    }

    private func noteRow(_ note: PersonNote, profileID: UUID) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(dateLabel(note.date))
                if let mood = note.mood {
                    Text("\(mood.emoji) \(loc.t(mood.labelKey))")
                }
            }
            .font(.caption)
            .foregroundColor(theme.primaryText.opacity(0.5))
            Text(note.text)
                .font(.body)
                .foregroundColor(theme.primaryText)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.07)))
        .contextMenu {
            Button(role: .destructive) {
                profileStore.removeNote(note.id, from: profileID)
            } label: {
                Label(loc.t("button_delete_note"), systemImage: "trash")
            }
        }
    }

    private func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = loc.language.locale
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Charts

    private func chartsSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.t("person_charts_title"))
                .font(.headline)
                .foregroundColor(theme.primaryText)

            NavigationLink(value: AppDestination.natalChart(profile)) {
                chartRow(icon: "star.fill", title: loc.t("person_natal_chart"))
            }
            .buttonStyle(.plain)

            NavigationLink(value: AppDestination.partnerChart(profile.id)) {
                chartRow(icon: "heart.fill", title: loc.t("person_partner_chart"))
            }
            .buttonStyle(.plain)
        }
    }

    private func chartRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            Text(title)
                .foregroundColor(theme.primaryText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.primaryText.opacity(0.4))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.07)))
    }
}

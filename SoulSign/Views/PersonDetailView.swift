//
//  PersonDetailView.swift
//  SoulSign
//
//  A person's page: the notes you've written about them first, then the
//  charts that belong to them. This is the main place a person lives in the
//  app, so the notes lead.
//
import SwiftUI
import CoreLocation

struct PersonDetailView: View {
    let profileID: UUID

    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var draft = ""
    @State private var moodDraft: Mood?
    @State private var showBreathing = false
    @State private var showingBirthEdit = false
    /// New identity per opening, so every pause starts on a clean first step.
    @State private var breathingSession = UUID()

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
                        birthDateRow(profile)
                        if profileStore.showsYouSection(for: profile) {
                            youSection(profile)
                        }
                        if profileStore.canWriteNotes(for: profile) {
                            notesSection(profile)
                        }
                        chartsSection(profile)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationTitle(profile?.firstName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBreathing) {
            BreathingPauseView()
                .id(breathingSession)
                .environmentObject(loc)
        }
        .sheet(isPresented: $showingBirthEdit) {
            if let profile {
                BirthDetailsEditor(profile: profile) { date, time, place, coordinates in
                    profileStore.updateBirthDetails(for: profile.id, date: date, time: time,
                                                    place: place, coordinates: coordinates)
                }
                .environmentObject(loc)
            }
        }
    }

    private func birthDateRow(_ profile: UserProfile) -> some View {
        Button {
            showingBirthEdit = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.t("section_birth_date"))
                        .font(.caption)
                        .foregroundColor(theme.primaryText.opacity(0.55))
                    Text(dateLabel(profile.birthDate))
                        .foregroundColor(theme.primaryText)
                    Text("\(timeLabel(profile.birthTime)) · \(profile.birthPlace)")
                        .font(.caption)
                        .foregroundColor(theme.primaryText.opacity(0.55))
                        .lineLimit(1)
                }
                Spacer()
                Text(loc.t("button_edit"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.primaryText.opacity(0.75))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
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
            if profileStore.canRecordMood(for: profile) {
                MoodPicker(selection: $moodDraft)
            }

            Button {
                breathingSession = UUID()
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
                profileStore.addNote(draft, to: profile.id,
                                     mood: profileStore.canRecordMood(for: profile) ? moodDraft : nil)
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
                if let mood = note.mood, showsMood(profileID) {
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

    private func showsMood(_ profileID: UUID) -> Bool {
        profileStore.profiles.first { $0.id == profileID }.map(profileStore.canRecordMood(for:)) ?? false
    }

    private func timeLabel(_ time: Date) -> String {
        let f = DateFormatter()
        f.locale = loc.language.locale
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: time)
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

/// Edits a person's birth date, time and place. Future dates are not allowed.
private struct BirthDetailsEditor: View {
    let profile: UserProfile
    let onSave: (Date, Date, String, CLLocationCoordinate2D?) -> Void

    @State private var date: Date
    @State private var time: Date
    @StateObject private var placeVM = PlaceSearchViewModel()
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    init(profile: UserProfile, onSave: @escaping (Date, Date, String, CLLocationCoordinate2D?) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _date = State(initialValue: profile.birthDate)
        _time = State(initialValue: profile.birthTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(loc.t("section_birth_date"))) {
                    DatePicker(loc.t("field_select_date"), selection: $date,
                               in: ...Date(), displayedComponents: .date)
                }

                Section(header: Text(loc.t("section_birth_time"))) {
                    DatePicker(loc.t("field_select_time"), selection: $time,
                               displayedComponents: .hourAndMinute)
                }

                Section(header: Text(loc.t("section_birth_place"))) {
                    BirthPlaceTextField(placeVM: placeVM)
                    ForEach(placeVM.suggestions, id: \.self) { suggestion in
                        Button {
                            placeVM.selectSuggestion(suggestion)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle).font(.caption).opacity(0.6)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .environment(\.locale, loc.language.locale)
            .onAppear {
                placeVM.prefill(placeName: profile.birthPlace, coordinates: profile.coordinates)
            }
            .navigationTitle(loc.t("birth_details_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(loc.t("button_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(loc.t("button_save_birth")) {
                        onSave(date, time, placeVM.selectedPlaceName, placeVM.selectedCoordinates)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(placeVM.selectedPlaceName.isEmpty)
                }
            }
        }
    }
}

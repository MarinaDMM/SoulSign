//
//  ProfileStore.swift
//  SoulSign
//
import Foundation

final class ProfileStore: ObservableObject {
    @Published var profiles: [UserProfile] = []
    private let key: String
    private let defaults: UserDefaults

    /// Storage is injectable so tests can run against an isolated
    /// UserDefaults suite instead of the shared, app-wide domain.
    init(defaults: UserDefaults = .standard, key: String = "soulsign_profiles_v1") {
        self.defaults = defaults
        self.key = key
        load()
    }

    func add(_ profile: UserProfile) {
        profiles.append(profile)
        save()
    }

    func update(_ profile: UserProfile) {
        guard let i = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[i] = profile
        save()
    }

    func remove(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        save()
    }

    /// The person marked as "you", if any.
    var me: UserProfile? { profiles.first { $0.isMe == true } }

    /// Whether the "This is you" switch should be offered on this person's page.
    /// Offered while nobody is "you" (to choose one), and on the person who is
    /// (so it can be turned off). Hidden on everyone else once someone is chosen.
    func showsYouSection(for profile: UserProfile) -> Bool {
        me == nil || profile.isMe == true
    }

    /// Marks one person as "you" and clears everyone else. Pass nil to clear.
    /// Readings cached for the old wording are dropped, so they regenerate
    /// in the new voice the next time they're opened.
    func setMe(_ profileID: UUID?) {
        for i in profiles.indices {
            profiles[i].isMe = (profiles[i].id == profileID) ? true : nil
            profiles[i].cachedReading = nil
            profiles[i].cachedReadingLanguage = nil
            profiles[i].cachedDeepReading = nil
            profiles[i].cachedDeepReadingLanguage = nil
        }
        save()
    }

    /// Adds a note for a person, newest first. Blank text is ignored.
    func addNote(_ text: String, to profileID: UUID, mood: Mood? = nil, now: Date = Date()) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let i = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        var notes = profiles[i].notes ?? []
        notes.insert(PersonNote(date: now, text: trimmed, mood: mood), at: 0)
        profiles[i].notes = notes
        save()
    }

    func removeNote(_ noteID: UUID, from profileID: UUID) {
        guard let i = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[i].notes?.removeAll { $0.id == noteID }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([UserProfile].self, from: data) else { return }
        profiles = decoded
    }
}

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

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

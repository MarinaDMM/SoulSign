//
//  ProfileStore.swift
//  SoulSign
//
import Foundation

final class ProfileStore: ObservableObject {
    @Published var profiles: [UserProfile] = []
    private let key = "soulsign_profiles_v1"

    init() { load() }

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
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([UserProfile].self, from: data) else { return }
        profiles = decoded
    }
}

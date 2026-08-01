//
//  TarotHistoryStore.swift
//  SoulSign
//
import Foundation

struct TarotHistoryEntry: Codable {
    var cardId: Int
    var reading: String
    var lang: String
    var isRedraw: Bool
}

/// Persists one tarot reading per calendar day, keyed by "yyyy-MM-dd" in the
/// device's current calendar/timezone. A re-draw overwrites that day's entry
/// rather than adding a second one, so history stays one card per day.
final class TarotHistoryStore {
    private let key: String
    private let defaults: UserDefaults
    private let maxEntries = 90

    init(defaults: UserDefaults = .standard, key: String = "tarot_history_v1") {
        self.defaults = defaults
        self.key = key
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        return f
    }()

    static func dayKey(for date: Date) -> String { dayFormatter.string(from: date) }

    func entry(for date: Date) -> TarotHistoryEntry? {
        all()[Self.dayKey(for: date)]
    }

    func save(_ entry: TarotHistoryEntry, for date: Date) {
        var dict = all()
        dict[Self.dayKey(for: date)] = entry
        persist(prune(dict))
    }

    /// All saved days, most recent first.
    func allSorted() -> [(dateKey: String, entry: TarotHistoryEntry)] {
        all().sorted { $0.key > $1.key }.map { (dateKey: $0.key, entry: $0.value) }
    }

    private func prune(_ dict: [String: TarotHistoryEntry]) -> [String: TarotHistoryEntry] {
        guard dict.count > maxEntries else { return dict }
        let keep = Set(dict.keys.sorted(by: >).prefix(maxEntries))
        return dict.filter { keep.contains($0.key) }
    }

    private func all() -> [String: TarotHistoryEntry] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: TarotHistoryEntry].self, from: data)
        else { return [:] }
        return decoded
    }

    private func persist(_ dict: [String: TarotHistoryEntry]) {
        if let data = try? JSONEncoder().encode(dict) {
            defaults.set(data, forKey: key)
        }
    }
}

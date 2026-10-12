//
//  Mood.swift
//  SoulSign
//
//  A gentle, optional check-in attached to a note or reflection. Deliberately
//  a few soft words rather than a score: the point is noticing how you feel,
//  not grading it. Stays on-device, like everything else in the journal.
//
import Foundation

enum Mood: String, Codable, CaseIterable, Hashable {
    case calm, grateful, hopeful, tired, anxious, sad

    var emoji: String {
        switch self {
        case .calm:     return "🌿"
        case .grateful: return "🙏"
        case .hopeful:  return "🌅"
        case .tired:    return "😴"
        case .anxious:  return "🌀"
        case .sad:      return "🌧️"
        }
    }

    /// Localization key for the mood's label.
    var labelKey: String { "mood_\(rawValue)" }
}

/// The last seven days, oldest first, with the mood recorded for each day if any.
/// Pure so it can be tested without a store or a clock.
enum MoodWeek {
    static func build(
        moodsByDay: [String: Mood],
        today: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [(day: Date, mood: Mood?)] {
        (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let key = dayKey(day, calendar: calendar)
            return (day: day, mood: moodsByDay[key])
        }
    }

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

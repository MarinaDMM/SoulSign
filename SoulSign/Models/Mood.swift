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

/// The calendar week containing today, Monday to Sunday, with the mood
/// recorded for each day if any. Monday is fixed as the first day so the
/// strip doesn't depend on the device's region. Pure, so it's testable.
enum MoodWeek {
    static func build(
        moodsByDay: [String: Mood],
        today: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> [(day: Date, mood: Mood?)] {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: weekStart) ?? today
            let key = dayKey(day, calendar: cal)
            return (day: day, mood: moodsByDay[key])
        }
    }

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

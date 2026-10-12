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
    // Ordered from good to bad: warmest states first, most stirred-up last.
    case grateful, hopeful, peaceful, atEase, calm, settling
    case tired, sad, anxious, onEdge, restless, overwhelmed

    var emoji: String {
        switch self {
        case .overwhelmed: return "🌊"
        case .restless:    return "🌪️"
        case .onEdge:      return "😬"
        case .anxious:     return "🌀"
        case .sad:         return "🌧️"
        case .tired:       return "😴"
        case .calm:        return "🌿"
        case .settling:    return "🍃"
        case .atEase:      return "🕊️"
        case .peaceful:    return "🌸"
        case .hopeful:     return "🌅"
        case .grateful:    return "🙏"
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

/// The breathing pattern, kept in one place so it can be tested. The exhale is
/// longer than the inhale, which is what slows the body down.
enum BreathingPattern {
    /// The first breath is a short, tense-feeling inhale followed by a long release.
    static let openingInhaleSeconds: Double = 2
    static let inhaleSeconds: Double = 4
    static let exhaleSeconds: Double = 8
    /// Session lengths offered to the user, in seconds.
    static let sessionOptions = [30, 40, 45, 50, 60, 90]
    static let defaultSessionSeconds = 60

    static func inhale(cycle: Int) -> Double {
        cycle == 0 ? openingInhaleSeconds : inhaleSeconds
    }
}

/// How tense or settled someone feels, as five soft words. Used before and
/// after the breathing pause. Shown on screen only, never stored.
enum Tension: Int, CaseIterable {
    case veryTense = 1, tense, steady, settled, calm

    var labelKey: String { "tension_\(rawValue)" }
}

//
//  MoodViews.swift
//  SoulSign
//
//  Calm-by-design pieces for the journal: an optional mood check-in, a short
//  breathing pause before writing, and a quiet seven-day strip on Home.
//  Nothing here scores, streaks, or pushes the user to do more.
//
import SwiftUI
import UIKit

// MARK: - Mood picker

/// A row of soft mood options. Tapping the selected mood clears it, since
/// the check-in is always optional.
struct MoodPicker: View {
    @Binding var selection: Mood?
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.t("mood_title"))
                .font(.subheadline)
                .foregroundColor(theme.primaryText.opacity(0.7))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        let isSelected = selection == mood
                        Button {
                            selection = isSelected ? nil : mood
                        } label: {
                            HStack(spacing: 6) {
                                Text(mood.emoji)
                                Text(loc.t(mood.labelKey))
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.white.opacity(isSelected ? 0.22 : 0.07)))
                            .overlay(Capsule().strokeBorder(.white.opacity(isSelected ? 0.5 : 0.14), lineWidth: 1))
                            .foregroundColor(theme.primaryText.opacity(isSelected ? 1 : 0.75))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Breathing pause

/// One minute of slow breathing: four seconds in, six seconds out. Dismissable
/// at any time, and it never asks for a result.
struct BreathingPauseView: View {
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var expanded = false
    @State private var breatheIn = true
    @State private var remaining = 60

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            NightSkyBackground()

            VStack(spacing: 36) {
                Text(loc.t("breathe_intro"))
                    .font(.subheadline)
                    .foregroundColor(theme.primaryText.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color(red: 0.75, green: 0.85, blue: 1.0).opacity(0.45), .clear],
                            center: .center, startRadius: 10, endRadius: 150))
                        .frame(width: 300, height: 300)
                    Circle()
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 150, height: 150)
                        .scaleEffect(expanded ? 1.6 : 1.0)
                }
                .animation(.easeInOut(duration: breatheIn ? 4 : 6), value: expanded)

                Text(breatheIn ? loc.t("breathe_in") : loc.t("breathe_out"))
                    .font(.title3.weight(.medium))
                    .foregroundColor(theme.primaryText)

                Text("\(remaining)s")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(theme.primaryText.opacity(0.5))

                Button(loc.t("button_close")) { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 28).padding(.vertical, 12)
                    .background(theme.secondaryButtonBg)
                    .foregroundColor(theme.secondaryButtonText)
                    .cornerRadius(12)
            }
            .padding()
        }
        .task { await breathe() }
        .onReceive(ticker) { _ in
            if remaining > 0 { remaining -= 1 } else { dismiss() }
        }
    }

    /// Alternates four seconds in and six seconds out until the view goes away.
    /// Taps mark the turning points, so the rhythm can be felt without looking:
    /// a firm tap when the circle is full (breathe out now), and two light taps
    /// when it is smallest (breathe in now). iOS respects the system haptics setting.
    private func breathe() async {
        let firm = UIImpactFeedbackGenerator(style: .medium)
        let light = UIImpactFeedbackGenerator(style: .light)
        firm.prepare()
        light.prepare()

        // First cue: breathe in.
        light.impactOccurred()
        while !Task.isCancelled {
            breatheIn = true
            expanded = true
            try? await Task.sleep(nanoseconds: 4_000_000_000)

            // Circle is full: breathe out.
            guard !Task.isCancelled else { break }
            firm.impactOccurred()
            breatheIn = false
            expanded = false
            try? await Task.sleep(nanoseconds: 6_000_000_000)

            // Circle is smallest: breathe in.
            guard !Task.isCancelled else { break }
            light.impactOccurred()
            try? await Task.sleep(nanoseconds: 150_000_000)
            light.impactOccurred()
        }
    }
}

// MARK: - Seven-day strip

/// Quiet view of the last seven days: one soft dot per day, showing the mood
/// if one was recorded. No numbers, no streaks.
struct MoodWeekStrip: View {
    let days: [(day: Date, mood: Mood?)]
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.t("week_title"))
                .font(.subheadline)
                .foregroundColor(theme.primaryText.opacity(0.7))

            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, item in
                    VStack(spacing: 6) {
                        Text(weekday(item.day))
                            .font(.caption2)
                            .foregroundColor(theme.primaryText.opacity(0.45))
                        ZStack {
                            Circle()
                                .fill(.white.opacity(item.mood == nil ? 0.06 : 0.14))
                                .frame(width: 34, height: 34)
                            if let mood = item.mood {
                                Text(mood.emoji).font(.system(size: 16))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.05)))
    }

    private func weekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = loc.language.locale
        f.setLocalizedDateFormatFromTemplate("EEEEE")
        return f.string(from: date)
    }
}

// MARK: - Safety line

/// Always-visible line pointing to people and emergency services. Shown under
/// the journal, never hidden behind a setting.
struct SafetyNote: View {
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        Text(loc.t("safety_footer"))
            .font(.caption2)
            .foregroundColor(theme.primaryText.opacity(0.5))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
    }
}

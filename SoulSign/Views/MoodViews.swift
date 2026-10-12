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

/// A short guided pause in three steps: how tense you feel, one minute of
/// breathing with a longer exhale, then how you feel now. The two tension
/// words are shown side by side at the end and are never stored.
struct BreathingPauseView: View {
    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    private enum Stage { case before, breathing, after }

    @State private var stage: Stage = .before
    @State private var tensionBefore: Tension?
    @State private var tensionAfter: Tension?
    @State private var expanded = false
    @State private var breatheIn = true
    @State private var inhaleLength = BreathingPattern.openingInhaleSeconds
    @State private var sessionLength = BreathingPattern.defaultSessionSeconds
    @State private var remaining = BreathingPattern.defaultSessionSeconds

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            NightSkyBackground()
            Group {
                switch stage {
                case .before:
                    tensionStep(
                        title: loc.t("tension_before_title"),
                        selection: $tensionBefore,
                        summary: nil,
                        durations: $sessionLength,
                        actionKey: "button_begin"
                    ) {
                        remaining = sessionLength
                        stage = .breathing
                    }
                case .breathing:
                    breathingStep
                case .after:
                    tensionStep(
                        title: loc.t("tension_after_title"),
                        selection: $tensionAfter,
                        summary: summary,
                        durations: nil,
                        actionKey: "button_done"
                    ) {
                        dismiss()
                    }
                }
            }
            .padding()
        }
        .onReceive(ticker) { _ in
            guard stage == .breathing else { return }
            if remaining > 0 { remaining -= 1 } else { stage = .after }
        }
        .task(id: stage) {
            if stage == .breathing { await breathe() }
        }
        .onAppear { resetSession() }
        .onDisappear { resetSession() }
    }

    /// Clears every answer and returns to the first step, so the next session
    /// never inherits the previous session's tension choices or timer.
    private func resetSession() {
        stage = .before
        tensionBefore = nil
        tensionAfter = nil
        remaining = sessionLength
        expanded = false
        breatheIn = true
    }

    private var summary: String? {
        guard let before = tensionBefore, let after = tensionAfter else { return nil }
        return "\(loc.t(before.labelKey))  →  \(loc.t(after.labelKey))"
    }

    // MARK: Steps

    private func tensionStep(
        title: String,
        selection: Binding<Tension?>,
        summary: String?,
        durations: Binding<Int>?,
        actionKey: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Text(title)
                .font(.title3.weight(.medium))
                .foregroundColor(theme.primaryText)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                ForEach(Tension.allCases, id: \.self) { tension in
                    let isSelected = selection.wrappedValue == tension
                    Button {
                        selection.wrappedValue = isSelected ? nil : tension
                    } label: {
                        Text(loc.t(tension.labelKey))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(isSelected ? 0.22 : 0.07)))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(isSelected ? 0.5 : 0.14), lineWidth: 1))
                            .foregroundColor(theme.primaryText.opacity(isSelected ? 1 : 0.75))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(theme.primaryText.opacity(0.8))
            }

            if let durations {
                durationPicker(durations)
            }

            Spacer()

            Button(loc.t(actionKey), action: action)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.secondaryButtonBg)
                .foregroundColor(theme.secondaryButtonText)
                .cornerRadius(12)
        }
        .padding(.horizontal, 8)
    }

    private func durationPicker(_ selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.t("duration_title"))
                .font(.subheadline)
                .foregroundColor(theme.primaryText.opacity(0.7))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BreathingPattern.sessionOptions, id: \.self) { seconds in
                        let isSelected = selection.wrappedValue == seconds
                        Button {
                            selection.wrappedValue = seconds
                        } label: {
                            Text(durationLabel(seconds))
                                .font(.subheadline)
                                .padding(.horizontal, 14)
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

    /// "30 sec", "1 min", "1.5 min". Whole minutes drop the decimal.
    private func durationLabel(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) \(loc.t("unit_sec"))"
        }
        if seconds % 60 == 0 {
            return "\(seconds / 60) \(loc.t("unit_min"))"
        }
        return String(format: "%.1f", Double(seconds) / 60) + " " + loc.t("unit_min")
    }

    private var breathingStep: some View {
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
            .animation(.easeInOut(duration: breatheIn ? inhaleLength : BreathingPattern.exhaleSeconds), value: expanded)

            Text(breatheIn ? loc.t("breathe_in") : loc.t("breathe_out"))
                .font(.title3.weight(.medium))
                .foregroundColor(theme.primaryText)

            Text("\(remaining) \(loc.t("unit_sec"))")
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(theme.primaryText.opacity(0.5))

            Button(loc.t("button_skip")) {
                stage = .after
            }
            .font(.subheadline)
            .foregroundColor(theme.primaryText.opacity(0.6))
        }
    }

    // MARK: Breathing

    /// Runs the breath cycle until the step changes. The first breath is short
    /// and tense-feeling, then every breath has a longer exhale than inhale.
    /// Taps mark the turning points: a firm tap when the circle is full (breathe
    /// out now), and two light taps when it is smallest (breathe in now). iOS
    /// respects the system haptics setting.
    private func breathe() async {
        let firm = UIImpactFeedbackGenerator(style: .medium)
        let light = UIImpactFeedbackGenerator(style: .light)
        firm.prepare()
        light.prepare()

        light.impactOccurred() // first cue: breathe in
        var cycle = 0
        while !Task.isCancelled {
            let inhale = BreathingPattern.inhale(cycle: cycle)
            inhaleLength = inhale
            breatheIn = true
            expanded = true
            try? await Task.sleep(nanoseconds: UInt64(inhale * 1_000_000_000))

            guard !Task.isCancelled else { break }
            firm.impactOccurred() // full: breathe out
            breatheIn = false
            expanded = false
            try? await Task.sleep(nanoseconds: UInt64(BreathingPattern.exhaleSeconds * 1_000_000_000))

            guard !Task.isCancelled else { break }
            light.impactOccurred() // smallest: breathe in
            try? await Task.sleep(nanoseconds: 150_000_000)
            light.impactOccurred()
            cycle += 1
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

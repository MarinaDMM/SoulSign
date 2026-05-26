//
//  Theme.swift
//  SoulSign
//
import SwiftUI

struct AppTheme {
    let colorScheme: ColorScheme
    private var isDark: Bool { colorScheme == .dark }

    // MARK: - Background
    var backgroundColors: [Color] {
        isDark
            ? [.black, .blue.opacity(0.6), .purple]
            : [Color(red: 0.97, green: 0.95, blue: 1.00),
               Color(red: 0.80, green: 0.72, blue: 0.96),
               Color(red: 0.55, green: 0.35, blue: 0.85)]
    }

    var sparkleOpacity: Double { isDark ? 0.30 : 0.15 }

    // MARK: - Text
    var primaryText: Color   { isDark ? .white        : Color(red: 0.18, green: 0.08, blue: 0.38) }
    var secondaryText: Color { isDark ? .white.opacity(0.85) : Color(red: 0.30, green: 0.18, blue: 0.50) }
    var fieldText: Color     { isDark ? .white        : Color(red: 0.18, green: 0.08, blue: 0.38) }

    // MARK: - Cards
    var cardBackground: Color { isDark ? .white.opacity(0.12) : .white }
    var cardText: Color       { isDark ? .white               : Color(red: 0.18, green: 0.08, blue: 0.38) }

    // MARK: - Buttons
    var primaryButtonBg: Color     { isDark ? .white                              : Color(red: 0.45, green: 0.18, blue: 0.78) }
    var primaryButtonText: Color   { isDark ? Color(red: 0.45, green: 0.18, blue: 0.78) : .white }
    var secondaryButtonBg: Color   { isDark ? .white.opacity(0.88)                : Color(red: 0.25, green: 0.08, blue: 0.58) }
    var secondaryButtonText: Color { isDark ? .blue                               : .white }

    // MARK: - Place suggestions
    var suggestionText: Color   { isDark ? .white              : Color(red: 0.18, green: 0.08, blue: 0.38) }
    var suggestionRowBg: Color  { isDark ? .white.opacity(0.1) : .purple.opacity(0.10) }
    var suggestionListBg: Color { isDark ? .black.opacity(0.3) : .white.opacity(0.85) }

    // MARK: - Navigation bar
    var navColorScheme: ColorScheme { isDark ? .dark : .light }
}

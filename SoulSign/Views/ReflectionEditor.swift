//
//  ReflectionEditor.swift
//  SoulSign
//
//  A private note the user writes for themselves next to a tarot card.
//  Never included in shared PDFs or share cards — this is a personal
//  journal, not content meant to be published outward.
//
import SwiftUI

struct ReflectionEditor: View {
    @Binding var text: String
    /// Overrides for reuse outside the daily card (e.g. notes about a person).
    /// Nil means the default daily-reflection wording.
    var titleKey: String = "reflection_title"
    var placeholderKey: String = "reflection_placeholder"
    var saveKey: String = "button_save_reflection"
    let onSave: () -> Void

    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    @State private var justSaved = false

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loc.t(titleKey))
                .font(.headline)
                .foregroundColor(theme.primaryText)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 92)
                    .padding(6)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(theme.primaryText)
                    .toolbar {
                        // A Done key above the keyboard, so the user can always close it.
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(loc.t("button_done")) { dismissKeyboard() }
                                .fontWeight(.semibold)
                        }
                    }

                if text.isEmpty {
                    Text(loc.t(placeholderKey))
                        .foregroundColor(theme.primaryText.opacity(0.35))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.07)))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.white.opacity(0.14), lineWidth: 1))

            Button {
                onSave()
                justSaved = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { justSaved = false }
            } label: {
                Text(justSaved ? loc.t("reflection_saved_button") : loc.t(saveKey))
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(theme.secondaryButtonBg)
                    .foregroundColor(theme.secondaryButtonText)
                    .cornerRadius(10)
            }
        }
    }
}

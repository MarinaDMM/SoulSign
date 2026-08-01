//
//  TarotHistoryView.swift
//  SoulSign
//
import SwiftUI

struct TarotHistoryView: View {
    let entries: [(dateKey: String, card: TarotCard, entry: TarotHistoryEntry)]

    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        NavigationStack {
            ZStack {
                NightSkyBackground()

                if entries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(entries, id: \.dateKey) { item in
                            NavigationLink {
                                TarotHistoryDetailView(
                                    card: item.card,
                                    reading: item.entry.reading,
                                    dateLabel: dateLabel(for: item.dateKey),
                                    isRedraw: item.entry.isRedraw
                                )
                            } label: {
                                row(item)
                            }
                            .listRowBackground(Color.white.opacity(0.07))
                            .listRowSeparatorTint(.white.opacity(0.12))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(loc.t("tarot_history_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(loc.t("button_close")) { dismiss() }
                        .foregroundColor(theme.primaryText)
                }
            }
        }
    }

    private func row(_ item: (dateKey: String, card: TarotCard, entry: TarotHistoryEntry)) -> some View {
        HStack(spacing: 14) {
            TarotCardFace(card: item.card)
                .frame(width: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.card.name)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                HStack(spacing: 6) {
                    Text(isToday(item.dateKey) ? loc.t("tarot_history_today") : dateLabel(for: item.dateKey))
                        .font(.caption)
                        .foregroundColor(theme.primaryText.opacity(0.55))
                    if item.entry.isRedraw {
                        Text(loc.t("tarot_redrawn_badge"))
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(.white.opacity(0.14)))
                            .foregroundColor(theme.primaryText.opacity(0.75))
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🃏").font(.system(size: 48))
            Text(loc.t("tarot_history_empty"))
                .font(.subheadline)
                .foregroundColor(theme.primaryText.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func isToday(_ dateKey: String) -> Bool {
        dateKey == TarotHistoryStore.dayKey(for: Date())
    }

    private func dateLabel(for dateKey: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dateKey) else { return dateKey }
        let f = DateFormatter()
        f.locale = loc.language.locale
        f.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
        return f.string(from: date)
    }
}

// MARK: - Detail

struct TarotHistoryDetailView: View {
    let card: TarotCard
    let reading: String
    let dateLabel: String
    let isRedraw: Bool

    @EnvironmentObject var loc: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    private var theme: AppTheme { AppTheme(colorScheme: colorScheme) }

    var body: some View {
        ZStack {
            NightSkyBackground()
            ScrollView {
                VStack(spacing: 24) {
                    Text(dateLabel.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .tracking(2.5)
                        .foregroundColor(theme.primaryText.opacity(0.45))

                    TarotCardFace(card: card)
                        .frame(maxWidth: 200)
                        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)

                    if isRedraw {
                        Text(loc.t("tarot_redrawn_badge"))
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(.white.opacity(0.14)))
                            .foregroundColor(theme.primaryText.opacity(0.8))
                    }

                    Text(reading)
                        .foregroundColor(theme.primaryText)
                        .font(.body)
                        .lineSpacing(5)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                TarotPDFShareButton(card: card, reading: reading, dateLabel: dateLabel.uppercased())
                    .foregroundColor(theme.primaryText)
            }
        }
    }
}

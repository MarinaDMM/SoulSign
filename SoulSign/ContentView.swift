//
//  ContentView.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//
import SwiftUI
import CoreLocation
import UserNotifications

struct ContentView: View {
    @StateObject private var viewModel = SoulSignViewModel()
    @State private var showAffirmations = false
    @EnvironmentObject var notificationRouter: NotificationRouter

    var body: some View {
        NavigationStack {
            ZStack {
                NightSkyBackground()

                if viewModel.chartResult.isEmpty {
                    UserInputView { fullName, birthDate, birthTime, birthPlace, coordinates in
                        Task {
                            await viewModel.generateChart(
                                fullName: fullName,
                                birthDate: birthDate,
                                birthTime: birthTime,
                                birthPlace: birthPlace,
                                coordinates: coordinates
                            )
                        }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("✨ Your SoulSign Reading")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(viewModel.chartResult)
                                .foregroundColor(.white)
                                .font(.body)
                                .multilineTextAlignment(.leading)

                            VStack(spacing: 12) {
                                Button("🔁 Generate Another Chart") {
                                    viewModel.chartResult = ""
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(.purple)
                                .cornerRadius(12)

                                Button("🌞 Daily Affirmations") {
                                    showAffirmations = true
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }

                if viewModel.isLoading {
                    VStack {
                        ProgressView("Generating Chart...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .foregroundColor(.black)
                            .padding()
                    }
                }

                if let error = viewModel.errorMessage {
                    Text("⚠️ \(error)")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationDestination(isPresented: $showAffirmations) {
                DailyAffirmationView()
            }
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationTitle("SoulSign")
            .onAppear {
                requestNotificationPermission()
                scheduleDailyAffirmationNotification()
            }
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveNotificationResponse)) { _ in
                DispatchQueue.main.async {
                    showAffirmations = true
                    notificationRouter.navigateToAffirmations = false
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("✅ Notifications authorized")
            } else {
                print("❌ Notifications denied")
            }
        }
    }

    private func scheduleDailyAffirmationNotification() {
        AffirmationService.fetchAffirmations { affirmations in
            guard let affirmations = affirmations else {
                print("❌ Failed to fetch affirmations for notification")
                return
            }

            let values = [
                affirmations.Finance,
                affirmations.Love,
                affirmations.MindSpirit,
                affirmations.Career,
                affirmations.Friendship,
                affirmations.Health
            ]

            let content = UNMutableNotificationContent()
            content.title = "🌟 Daily Affirmation"
            content.body = values.randomElement() ?? "You are amazing."
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = 10
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "daily_affirmation", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    print("✅ Daily notification scheduled")
                }
            }
        }
    }
}

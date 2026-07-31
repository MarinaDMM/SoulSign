//
//  SoulSignApp.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//
import SwiftUI
import UserNotifications

@main
struct SoulSignApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @StateObject private var notificationRouter: NotificationRouter
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var subscriptions = SubscriptionManager.shared

    private let notificationDelegate: NotificationDelegate

    init() {
        // (The -uitest-reset hook lives in AppDelegate, which runs earlier.)
        let router = NotificationRouter()
        self._notificationRouter = StateObject(wrappedValue: router)
        let delegate = NotificationDelegate(router: router)
        self.notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenWelcome {
                HomeView()
                    .environmentObject(notificationRouter)
                    .environmentObject(profileStore)
                    .environmentObject(localization)
                    .environmentObject(subscriptions)
                    .environment(\.locale, localization.language.locale)
                    .task { await subscriptions.refreshEntitlement() }
            } else {
                WelcomeView()
                    .environmentObject(localization)
                    .environment(\.locale, localization.language.locale)
            }
        }
    }
}

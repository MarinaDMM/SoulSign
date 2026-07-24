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

    private let notificationDelegate: NotificationDelegate

    init() {
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
                    .environment(\.locale, localization.language.locale)
            } else {
                WelcomeView()
                    .environmentObject(localization)
                    .environment(\.locale, localization.language.locale)
            }
        }
    }
}

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

    // 🔒 Strong reference to keep delegate alive
    private let notificationDelegate: NotificationDelegate

    init() {
        // Initialize the router
        let router = NotificationRouter()
        self._notificationRouter = StateObject(wrappedValue: router)

        // Assign the delegate and keep a strong reference
        let delegate = NotificationDelegate(router: router)
        self.notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            if hasSeenWelcome {
                ContentView()
                    .environmentObject(notificationRouter)
            } else {
                WelcomeView()
            }
        }
    }
}

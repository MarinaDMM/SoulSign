//
//  AppDelegate.swift
//  SoulSign
//
//  Created by Marina Dedikova on 04/06/2025.
//
import UIKit
import UserNotifications


class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // UI-test hook: runs before SwiftUI builds any StateObject, so it
        // reliably wipes saved profiles for a deterministic empty start.
        // Guarded by a launch argument, so real users are never affected.
        if ProcessInfo.processInfo.arguments.contains("-uitest-reset") {
            UserDefaults.standard.removeObject(forKey: "soulsign_profiles_v1")
        }

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print(granted ? "✅ Notifications allowed" : "❌ Notifications denied")
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: .didReceiveNotificationResponse, object: response)
        completionHandler()
    }
}

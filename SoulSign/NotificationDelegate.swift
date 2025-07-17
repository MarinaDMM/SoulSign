//
//  NothificationsDelegate.swift
//  SoulSign
//
//  Created by Marina Dedikova on 17/07/2025.
//
import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let router: NotificationRouter

    init(router: NotificationRouter) {
        self.router = router
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📲 Notification tapped – navigating to Daily Affirmations")
        router.navigateToAffirmations = true
        completionHandler()
    }
}

//
//  AppDelegate.swift
//  SoulSign
//
//  Created by Marina Dedikova on 04/06/2025.
//
import UIKit
import GoogleMaps
import GooglePlaces
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String {
            GMSServices.provideAPIKey(mapsKey)
        }

        if let placesKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String {
            GMSPlacesClient.provideAPIKey(placesKey)
        }

        print("MAPS KEY:", Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") ?? "❌ missing")
        print("PLACES KEY:", Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") ?? "❌ missing")

        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                print("✅ Notifications allowed")
            } else {
                print("❌ Notifications denied")
            }
        }
    }

    // Handle notification tap to flag app launch
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        UserDefaults.standard.set(true, forKey: "launchedFromNotification")
        completionHandler()
    }
} 

//
//  AppDelegate.swift
//  SoulSign
//
//  Created by Marina Dedikova on 04/06/2025.
//
import UIKit
import GoogleMaps
import GooglePlaces

class AppDelegate: UIResponder, UIApplicationDelegate {
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


        return true
    }
}

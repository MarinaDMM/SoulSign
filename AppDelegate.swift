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
        GMSServices.provideAPIKey("AIzaSyDNQCvqZbZ8i-PxTyNA4uVZW2WmULRJZwk")
        GMSPlacesClient.provideAPIKey("AIzaSyDNQCvqZbZ8i-PxTyNA4uVZW2WmULRJZwk")
        return true
    }
}

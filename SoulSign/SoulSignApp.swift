//
//  SoulSignApp.swift
//  SoulSign
//
//  Created by Marina Dedikova on 09/05/2025.
//

import SwiftUI

@main
struct SoulSignApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some Scene {
        WindowGroup {
            if hasSeenWelcome {
                ContentView()
            } else {
                WelcomeView()
            }
        }
    }
}

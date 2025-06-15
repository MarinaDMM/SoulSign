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
            Group {
                if hasSeenWelcome {
                    ContentView()
                } else {
                    WelcomeView()
                }
            }
            .onAppear {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.windows.first?.overrideUserInterfaceStyle = .light
                }
            }
        }
    }
}

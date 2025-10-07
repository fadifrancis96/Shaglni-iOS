//
//  ShaglniApp.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI
import FirebaseCore

@main
struct ShaglniApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var localization = LocalizationManager()
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // TODO: Uncomment when you add FirebaseMessaging to enable push notifications
        // PushNotificationService.shared.registerForPushNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(localization)
        }
    }
}

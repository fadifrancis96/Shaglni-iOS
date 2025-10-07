//
//  AppDelegate.swift
//  Shaglni
//
//  Created on October 2025
//
//  OPTIONAL FILE: This is only needed when you enable Push Notifications
//  To use this file:
//  1. Add FirebaseMessaging package to your Xcode target
//  2. Uncomment the import and code below
//  3. In ShaglniApp.swift, add: @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//  4. Remove the init() method from ShaglniApp.swift
//

import UIKit
import FirebaseCore
// TODO: Uncomment when FirebaseMessaging is added
// import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // TODO: Uncomment when FirebaseMessaging is added
        // Register for push notifications
        // PushNotificationService.shared.registerForPushNotifications()
        
        return true
    }
    
    // TODO: Uncomment when FirebaseMessaging is added
    // func application(_ application: UIApplication,
    //                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    //     print("📱 Device registered for remote notifications")
    //     Messaging.messaging().apnsToken = deviceToken
    // }
    //
    // func application(_ application: UIApplication,
    //                 didFailToRegisterForRemoteNotificationsWithError error: Error) {
    //     print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    // }
}


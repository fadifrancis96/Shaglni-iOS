//
//  PushNotificationService.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications

class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    private let db = Firestore.firestore()
    @Published var fcmToken: String?
    
    private override init() {
        super.init()
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if granted {
                    print("✅ Push notification permission granted")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else if let error = error {
                    print("❌ Error requesting push notification permission: \(error.localizedDescription)")
                } else {
                    print("⚠️ Push notification permission denied")
                }
            }
        )
        
        Messaging.messaging().delegate = self
    }
    
    func saveFCMToken(userId: String, token: String) {
        print("💾 Saving FCM token for user: \(userId)")
        db.collection("users").document(userId).updateData([
            "fcmToken": token,
            "fcmTokenUpdatedAt": Date()
        ]) { error in
            if let error = error {
                print("❌ Error saving FCM token: \(error.localizedDescription)")
            } else {
                print("✅ FCM token saved successfully")
            }
        }
    }
    
    func removeFCMToken(userId: String) {
        print("🗑️ Removing FCM token for user: \(userId)")
        db.collection("users").document(userId).updateData([
            "fcmToken": FieldValue.delete()
        ]) { error in
            if let error = error {
                print("❌ Error removing FCM token: \(error.localizedDescription)")
            } else {
                print("✅ FCM token removed successfully")
            }
        }
    }
    
    // MARK: - Send Notifications
    
    func sendOfferNotification(to userId: String, jobTitle: String, contractorName: String, price: Double) {
        print("📬 Preparing offer notification for user: \(userId)")
        
        // Fetch user's FCM token
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let token = snapshot?.data()?["fcmToken"] as? String else {
                print("⚠️ No FCM token found for user")
                return
            }
            
            let notification = NotificationPayload(
                to: token,
                notification: NotificationContent(
                    title: "New Offer Received!",
                    body: "\(contractorName) offered ₪\(Int(price)) for \(jobTitle)"
                ),
                data: [
                    "type": "new_offer",
                    "jobTitle": jobTitle
                ]
            )
            
            self?.sendToFCM(notification)
        }
    }
    
    func sendOfferResponseNotification(to userId: String, jobTitle: String, status: OfferStatus, counterPrice: Double? = nil) {
        print("📬 Preparing offer response notification for user: \(userId)")
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let token = snapshot?.data()?["fcmToken"] as? String else {
                print("⚠️ No FCM token found for user")
                return
            }
            
            var body: String
            switch status {
            case .accepted:
                body = "Your offer for \(jobTitle) was accepted! 🎉"
            case .rejected:
                body = "Your offer for \(jobTitle) was declined."
            case .counterOffer:
                if let price = counterPrice {
                    body = "Counter offer: ₪\(Int(price)) for \(jobTitle)"
                } else {
                    body = "The job poster wants to negotiate the price for \(jobTitle)"
                }
            case .pending:
                body = "Status update for \(jobTitle)"
            }
            
            let notification = NotificationPayload(
                to: token,
                notification: NotificationContent(
                    title: "Offer Update",
                    body: body
                ),
                data: [
                    "type": "offer_response",
                    "status": status.rawValue,
                    "jobTitle": jobTitle
                ]
            )
            
            self?.sendToFCM(notification)
        }
    }
    
    private func sendToFCM(_ payload: NotificationPayload) {
        // Note: In production, you should send this through your backend server
        // Firebase Cloud Functions is the recommended way to send FCM notifications
        // For now, we'll store the notification in Firestore and trigger it via Cloud Functions
        
        do {
            let notificationData = try Firestore.Encoder().encode(payload)
            db.collection("pendingNotifications").addDocument(data: notificationData) { error in
                if let error = error {
                    print("❌ Error queueing notification: \(error.localizedDescription)")
                } else {
                    print("✅ Notification queued successfully")
                }
            }
        } catch {
            print("❌ Error encoding notification: \(error.localizedDescription)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📩 Received notification while app is in foreground")
        completionHandler([[.banner, .sound, .badge]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 User tapped on notification")
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let type = userInfo["type"] as? String {
            print("Notification type: \(type)")
            // You can post a notification to navigate to specific screens
            NotificationCenter.default.post(name: .didReceivePushNotification, object: nil, userInfo: userInfo)
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        print("🎫 FCM Token received: \(token)")
        self.fcmToken = token
        
        // Save token to Firestore when user is logged in
        // This will be called from AuthViewModel after successful login
    }
}

// MARK: - Models

struct NotificationPayload: Codable {
    let to: String
    let notification: NotificationContent
    let data: [String: String]
}

struct NotificationContent: Codable {
    let title: String
    let body: String
}

// MARK: - Notification Names

extension Notification.Name {
    static let didReceivePushNotification = Notification.Name("didReceivePushNotification")
}


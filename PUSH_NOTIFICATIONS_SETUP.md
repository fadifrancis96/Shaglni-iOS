# Push Notifications Setup Guide for Shaglni App

## Overview
This guide will help you set up push notifications for the Shaglni app using Firebase Cloud Messaging (FCM).

## Prerequisites
- Firebase project already configured (✅ Done)
- Xcode project with Firebase SDK (✅ Done)
- Apple Developer Account (Required for push notifications)

## Step 1: Add Firebase Cloud Messaging Package to Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Search for: `https://github.com/firebase/firebase-ios-sdk`
4. Select version **12.3.0** (already resolved in your project)
5. In the package products, **ADD** the following (if not already added):
   - ✅ FirebaseAuth (Already added)
   - ✅ FirebaseFirestore (Already added)
   - ✅ FirebaseStorage (Already added)
   - ➕ **FirebaseMessaging** (ADD THIS)

### How to Add FirebaseMessaging:
1. In Xcode, select your project in the navigator
2. Select your target "Shaglni"
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click the **+** button
6. Search for "FirebaseMessaging"
7. Add it to your target

## Step 2: Enable Push Notifications Capability in Xcode

1. In Xcode, select your project
2. Select your target "Shaglni"
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add:
   - **Push Notifications**
   - **Background Modes**
     - Enable: "Remote notifications"

## Step 3: Configure APNs in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **shagla-project**
3. Go to **Project Settings** (gear icon) → **Cloud Messaging**
4. Scroll to **Apple app configuration**
5. Upload your APNs Authentication Key or APNs Certificate:

### Option A: APNs Authentication Key (Recommended)
1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Go to **Keys** → Click **+** to create a new key
4. Enable **Apple Push Notifications service (APNs)**
5. Download the `.p8` key file
6. Upload this key to Firebase Console with:
   - Key ID
   - Team ID (found in Apple Developer account)

### Option B: APNs Certificate (Legacy)
1. Generate a certificate in Apple Developer Portal
2. Export it as `.p12`
3. Upload to Firebase Console

## Step 4: Update App Entitlements

Xcode should automatically create an entitlements file. Verify it contains:

```xml
<key>aps-environment</key>
<string>development</string>
```

For production builds, this should be `production`.

## Step 5: Deploy Firebase Cloud Functions

The notification logic requires Firebase Cloud Functions to send notifications securely.

### Install Firebase CLI:
```bash
npm install -g firebase-tools
```

### Login to Firebase:
```bash
firebase login
```

### Initialize Functions:
```bash
cd /Users/fadif/ShaglniAppIOS/Shaglni
firebase init functions
```

Choose:
- Language: **JavaScript** or **TypeScript** (recommended)
- ESLint: Yes (optional)
- Install dependencies: Yes

### Copy the Function Code:
Copy the content from `firebase-functions-template.js` to `functions/index.js`

### Deploy Functions:
```bash
firebase deploy --only functions
```

## Step 6: Test Push Notifications

### Test on Simulator (Limited):
⚠️ **Note**: iOS Simulator does NOT support push notifications. You must test on a physical device.

### Test on Physical Device:
1. Connect your iPhone/iPad
2. Build and run the app on the device
3. Accept the push notification permission prompt
4. The app will log the FCM token to the console
5. Test by:
   - Job Poster: Post a job, have a contractor submit an offer
   - Contractor: Submit an offer, have the job poster respond

## Step 7: Verify Setup

### Check Console Logs:
Look for these success messages:
```
✅ Push notification permission granted
🎫 FCM Token received: [token]
💾 Saving FCM token for user: [userId]
```

### Check Firestore:
1. Go to Firebase Console → Firestore Database
2. Open a user document
3. Verify `fcmToken` field exists

### Test Notification Flow:
1. **New Offer Notification**:
   - Contractor submits offer → Job poster receives notification
   
2. **Offer Accepted Notification**:
   - Job poster accepts offer → Contractor receives "Offer accepted! 🎉"
   
3. **Offer Declined Notification**:
   - Job poster declines offer → Contractor receives "Offer declined"
   
4. **Counter Offer Notification**:
   - Job poster sends counter offer → Contractor receives "Counter offer: ₪[price]"

## Troubleshooting

### Issue: "No FCM token found"
**Solution**: Make sure the user is logged in and the app has notification permissions.

### Issue: Notifications not received
**Check**:
1. APNs certificate/key is correctly uploaded to Firebase
2. App has "Push Notifications" capability enabled
3. Device has internet connection
4. User granted notification permissions
5. Firebase Cloud Functions are deployed and running

### Issue: "Error requesting push notification permission"
**Solution**: 
1. Delete the app from device
2. Rebuild and reinstall
3. The permission prompt will appear again

### Debug Logs:
Enable detailed Firebase logging in AppDelegate:
```swift
FirebaseConfiguration.shared.setLoggerLevel(.debug)
```

## Security Rules Update

Make sure your Firestore security rules allow writing FCM tokens:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /pendingNotifications/{notificationId} {
      allow create: if request.auth != null;
    }
  }
}
```

## Production Checklist

Before deploying to App Store:
- [ ] Upload production APNs certificate/key to Firebase
- [ ] Update `aps-environment` to `production`
- [ ] Test with production build (TestFlight)
- [ ] Monitor Firebase Cloud Functions logs
- [ ] Set up error monitoring (Firebase Crashlytics)
- [ ] Handle notification tap navigation

## Additional Features to Consider

1. **Rich Notifications**: Add images, action buttons
2. **Notification Settings**: Let users customize notification preferences
3. **Badge Count**: Update app icon badge with unread notifications
4. **Silent Notifications**: Update data in background
5. **Notification History**: Store notification history in Firestore

## Support

If you encounter issues:
1. Check Firebase Console logs
2. Check Xcode console logs
3. Verify Cloud Functions are running
4. Test FCM token registration
5. Ensure all security rules are correct

## Code Structure

- **PushNotificationService.swift**: Main service handling FCM registration and notification sending
- **AppDelegate.swift**: Handles app lifecycle and FCM setup
- **FirestoreService.swift**: Integrates notifications when offers are created/updated
- **AuthViewModel.swift**: Manages FCM token on login/logout
- **firebase-functions-template.js**: Cloud Functions for server-side notification delivery

---

✅ Setup complete! Users will now receive push notifications for offer updates.


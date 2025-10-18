# Shaglni Android

Native Android implementation (Jetpack Compose, Kotlin, Firebase Auth + Firestore, Hilt, Navigation). No FCM yet.

## Prerequisites
- Android Studio (Ladybug or newer)
- JDK 17
- Firebase project with `google-services.json`

## Setup
1. Open Android Studio → Open `android/` folder.
2. Place `google-services.json` in `app/`.
3. Sync Gradle.

## Run
- Select an emulator or device
- Click Run (Shift+F10)

## Structure
- `app/src/main/java/com/shaglni/app/`
  - `MainActivity.kt` – Compose entry
  - `ShaglniApp.kt` – Hilt application
  - `data/model/` – Kotlin data classes (User, Job, Offer, ContractorProfile)
  - `data/FirestoreService.kt` – Firestore access layer
  - `ui/auth/AuthViewModel.kt` – Auth + role flags
  - `ui/navigation/NavGraph.kt` – Role-based tabs
  - `ui/screens/PlaceholderScreens.kt` – Placeholder screens

## Notes
- Maps dependency included; add API key in `AndroidManifest.xml` if enabling Maps.
- FCM is intentionally excluded for now.



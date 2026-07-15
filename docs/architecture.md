# Shaglni — Architecture

A short reference for engineers working on the codebase.

## High-level shape

```
┌──────────────────────────────────────────────────────────────────┐
│  SwiftUI views                                                   │
│   • Observe @Published state on repositories via                 │
│     @EnvironmentObject (injected in ShaglniApp.body)             │
│   • Call repository methods (`Task { try await … }`)             │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────┐
│  Repository layer  (Shaglni/Repositories/*)                      │
│   • JobsRepository      — openJobs, myPostedJobs, myActiveJobs   │
│   • OffersRepository    — myOffers, per-job listener helper      │
│   • ContractorsRepository — allContractors, myProfile            │
│   • PortfolioRepository — myPortfolio                            │
│   • ChatRepository      — myThreads, send/listen messages        │
│                                                                  │
│   Each repository:                                               │
│     - @MainActor singleton + @Published arrays                   │
│     - Async/await mutations (no completion handlers)             │
│     - Firestore `addSnapshotListener` for live state             │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌─────────────────────────────┐
              │  Firestore + Storage + Auth │
              └─────────────────────────────┘
```

## Data model

* `users/{uid}` — one doc per user. `role` decides which dashboard is shown.
* `jobs/{jobId}` — created by job posters. **Denormalised** with the
  accepted offer (`acceptedOfferId`, `acceptedContractorId`, `acceptedPrice`,
  `acceptedAt`) so we can query *"jobs I won"* with a single
  `whereField("acceptedContractorId", isEqualTo: uid)`.
* `jobs/{jobId}/offers/{offerId}` — contractors submit; job poster
  responds (accept, decline, counter); contractor can accept the counter
  (which sets `contractorAcceptedCounter=true`) at which point the job
  poster finalises with `OffersRepository.acceptOfferAndCloseOthers(...)`
  — a single batch that:
    1. Sets the accepted offer's status & `finalPrice`.
    2. Rejects all sibling pending/counter offers.
    3. Denormalises the accepted offer fields onto the job.
* `completedJobs/{id}` — entries the contractor adds to their portfolio
  when they mark a job complete.
* `contractorProfiles/{uid}` — bio, skills, location, rating.
* `chats/{jobId}` — created automatically when an offer is accepted.
  `chats/{jobId}/messages/{id}` is the message log.

## Auth flow

1. App launches; `AuthViewModel.init` attaches a Firebase auth state listener.
2. On a state change, we set up a **document listener** on `users/{uid}`
   so role changes propagate immediately.
3. `ContentView` waits for **both** `currentUser` and `currentUserData`
   (`isReady` → true) before showing `MainTabView`. This eliminates the
   flash where the tab bar appeared briefly with the wrong role.
4. When the user signs out, we tear down every repository listener and
   reset @Published arrays.

## Localization

* `Shaglni/Localization/Localizable.xcstrings` is the source of truth.
* `L10n.swift` provides typed key accessors (`L10n.Tab.jobs.string`).
* `LocalizationManager` switches the active **language bundle** by setting
  `Bundle.localized` — this lets `L10n` resolve to the chosen language
  without restarting the app.
* Legacy `localization.localized("key")` callers still work via a small
  hardcoded fallback table in `LegacyStrings`. Migrate to `L10n` over time
  and delete the table.

## Security model

* See `firestore.rules` and `storage.rules` for the canonical rules.
* Each Firestore collection has explicit `read` / `create` / `update` /
  `delete` rules anchored to `request.auth.uid`.
* Storage rules require JPEG/PNG ≤ 10 MB, and scope writes to
  per-user paths (`users/{uid}/profile/*`,
  `contractors/{uid}/portfolio/*`, etc.).

## Conventions

* **Logging**: `AppLogger.<domain>.info(...)` — never `print(...)` in
  new code. Configure verbosity per category in Console.app.
* **Money**: `Money.string(value)` — never hand-roll `"₪\(Int(x))"`.
* **Remote images**: `RemoteImage` / `RemoteThumbnail` — no raw
  `URLSession.dataTask`. Cached via `URLCache.shared` (50 MB mem /
  200 MB disk, set up in `ShaglniApp.init`).
* **Errors** for user-facing layers: `AppError.*` (localized).

## Extending the system

Adding a feature follows a predictable script:

1. **Model**: add or edit a struct in `Models/` (or `Shaglni/Models/`).
   Optional new fields don't require any migration.
2. **Repository**: add a method on the matching `*Repository`. Use a
   batch (`db.batch()`) when more than one document changes together.
3. **Rules**: tighten `firestore.rules` / `storage.rules`. Deploy them.
4. **View**: observe `@Published` state and call the new method from a
   `Task { try await … }`.

Keep view files thin — anything more than basic state goes in a
`ViewModel` so it can be unit-tested.

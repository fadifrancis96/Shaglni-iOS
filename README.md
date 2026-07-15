# Shaglni — Marketplace for Local Service Work

Shaglni connects **job posters** (homeowners, businesses) with **contractors**
(plumbers, electricians, painters, etc.) in Hebrew, Arabic and English.

| Job posters can…                | Contractors can…                                |
|---------------------------------|-------------------------------------------------|
| Post a job with photos + budget | Browse open jobs and submit offers              |
| Receive offers from contractors | Negotiate a price with the job poster           |
| Counter-offer or accept         | Accept, decline, or counter the counter-offer   |
| Mark a job in progress / done   | Mark the job complete, add a portfolio entry    |
| Chat with the chosen contractor | Chat with the job poster after acceptance       |

## Running the app

1. **Open the project** in Xcode 16 or newer:
   `Shaglni.xcodeproj`
2. **Resolve packages** — Xcode auto-fetches the Firebase iOS SDK on first build.
3. **Pick a simulator** (iPhone 15 or later — deployment target is iOS 18.5).
4. **⌘ R** to run.

The bundled `GoogleService-Info.plist` points at a test Firebase project
(`shagla-project`). Replace it with your own if you fork.

## Project layout

```
Shaglni/                       # Xcode-managed source root (auto-syncs new files)
  Repositories/                # JobsRepository, OffersRepository, etc.
  Models/                      # ChatThread
  Utilities/                   # AppLogger, Money, RemoteImage, AppError
  Localization/                # Localizable.xcstrings + L10n typed accessors
  Views/Chat/                  # In-app chat UI
Models/                        # Job, Offer, User, ContractorProfile (legacy location)
Services/                      # FirestoreService compat layer + PhotoUploadService + LocalizationManager
ViewModels/                    # AuthViewModel
Views/                         # Auth, Components, Contractors, Dashboard, Jobs, Offers
firestore.rules                # Firestore security rules
storage.rules                  # Storage security rules
docs/architecture.md           # How the pieces fit together
```

## Architecture in 30 seconds

* **Repositories** (`Shaglni/Repositories/*.swift`) own all Firestore I/O.
  Each one exposes `@Published` arrays backed by `addSnapshotListener` so the
  UI reflects DB state in real time — no polling, no `NotificationCenter`.
* **AuthViewModel** owns the session and starts/stops repository listeners
  when the user signs in or out.
* **Views** observe repositories via `@EnvironmentObject` (injected in
  `ShaglniApp.body`) and call mutation methods directly (`Task { try await … }`).
* **Localization** uses Apple's String Catalog (`Localizable.xcstrings`)
  with a typed accessor (`L10n.Tab.jobs.string`). A small `LocalizationManager`
  switches the active language bundle at runtime — no app restart needed.

For a deeper tour see [`docs/architecture.md`](docs/architecture.md).

## Configuring Firebase rules

The repository ships hardened rules:

```bash
firebase deploy --only firestore:rules,storage
```

Highlights:

* **`jobs`** — anyone signed-in can read; only the creator can write/delete.
* **`jobs/{id}/offers`** — job posters see all offers, contractors see only
  their own. New offers must start as `pending`.
* **`completedJobs`** — contractor can only create entries with their own
  `contractorId`.
* **`chats/{jobId}`** — read/write limited to the two participants.
* **Storage** — per-user paths, JPEG/PNG only, 10 MB max.

## Common tasks

| Task                            | File / Location |
|---------------------------------|------------------|
| Add a new localized string      | `Shaglni/Localization/Localizable.xcstrings` (+ key in `L10n.swift`) |
| Add a new Firestore field       | The model in `Models/` (Xcode synthesises decoders) |
| Add a new repository method     | The repository under `Shaglni/Repositories/` |
| Tighten/loosen security         | `firestore.rules` / `storage.rules` |
| Adjust currency formatting      | `Shaglni/Utilities/Money.swift` |
| Image caching                   | `Shaglni/Utilities/RemoteImage.swift` |

## What's intentionally not here

* **Push notifications** — the previous prototype shipped a half-wired
  FirebaseMessaging integration that did nothing useful without a deployed
  Cloud Function. It has been removed. Add it back by re-introducing
  `FirebaseMessaging` and deploying a Cloud Function that watches
  `chats/{jobId}/messages` and `jobs/{id}/offers`.
* **Reviews / ratings UX** — the data model has a `rating` field but no UI
  to leave one yet. Easy follow-up.
* **Pagination** — for an MVP-scale dataset Firestore returns everything in
  one shot. Once you have hundreds of jobs, add `.limit(...)` + cursor
  paging to `JobsRepository`.

## License

Internal project — all rights reserved.

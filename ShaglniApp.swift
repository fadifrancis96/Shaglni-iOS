//
//  ShaglniApp.swift
//  Shaglni
//

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

/// App Attest with automatic fallback handled by Firebase. Debug builds use the
/// debug provider so the simulator keeps working (paste the token it logs into
/// Firebase console → App Check → Manage debug tokens).
final class ShaglniAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        AppAttestProvider(app: app)
    }
}

@main
struct ShaglniApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var localization  = LocalizationManager.shared
    @StateObject private var jobsRepo      = JobsRepository.shared
    @StateObject private var offersRepo    = OffersRepository.shared
    @StateObject private var contractorsRepo = ContractorsRepository.shared
    @StateObject private var portfolioRepo = PortfolioRepository.shared
    @StateObject private var chatRepo      = ChatRepository.shared

    init() {
        // App Check factory must be set BEFORE FirebaseApp.configure().
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(ShaglniAppCheckProviderFactory())
        #endif
        FirebaseApp.configure()
        Self.configureImageCache()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(localization)
                .environmentObject(jobsRepo)
                .environmentObject(offersRepo)
                .environmentObject(contractorsRepo)
                .environmentObject(portfolioRepo)
                .environmentObject(chatRepo)
                .appLanguageDirection(localization)
        }
    }

    /// Larger URLCache so `AsyncImage` (and our `RemoteImage` wrapper) can satisfy most
    /// portfolio/job thumbnails out of memory or disk without re-fetching.
    private static func configureImageCache() {
        let cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity:   200 * 1024 * 1024,
            diskPath:       "shaglni_images"
        )
        URLCache.shared = cache
    }
}

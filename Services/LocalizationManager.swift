//
//  LocalizationManager.swift
//  Shaglni
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic  = "ar"
    case hebrew  = "he"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic:  return "العربية"
        case .hebrew:  return "עברית"
        }
    }

    var isRTL: Bool { self == .arabic || self == .hebrew }
}

/// Source of truth for the active in-app language. Updates a `Bundle.localized` reference
/// used by `L10n` so language switches take effect immediately without restarting the app.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.storageKey)
            Bundle.localized = Self.bundle(for: currentLanguage)
        }
    }

    var isRTL: Bool { currentLanguage.isRTL }

    private static let storageKey = "app_language"

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey).flatMap(AppLanguage.init(rawValue:))
        let initial = saved ?? .arabic
        self.currentLanguage = initial
        Bundle.localized = Self.bundle(for: initial)
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    /// Returns a `Bundle` scoped to the given language's `.lproj` directory.
    /// Falls back to the main bundle if a per-language bundle can't be resolved (e.g. when
    /// the project is built without any explicit `.lproj` folders — Xcode auto-generates them
    /// for languages used in the String Catalog when LOCALIZATION_PREFERS_STRING_CATALOGS=YES).
    private static func bundle(for language: AppLanguage) -> Bundle {
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let lprojBundle = Bundle(path: path) {
            return lprojBundle
        }
        return .main
    }

}

extension Bundle {
    /// Thread-local-safe (`@MainActor`-driven) reference to the active language bundle.
    /// Reset by `LocalizationManager.setLanguage(_:)`.
    fileprivate(set) static var localized: Bundle = .main
}

// MARK: - Layout direction modifier

extension View {
    /// Mirrors the entire view hierarchy based on the active language.
    func appLanguageDirection(_ manager: LocalizationManager) -> some View {
        environment(\.layoutDirection, manager.isRTL ? .rightToLeft : .leftToRight)
    }
}

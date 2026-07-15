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

    // MARK: - Backwards compatibility shim for older call sites
    /// First tries the active String Catalog bundle, then falls back to a hardcoded
    /// table for legacy unprefixed keys ("dashboard", "jobs", etc.). New code should
    /// use `L10n.*` directly — this exists so existing views compile during migration.
    func localized(_ key: String) -> String {
        let resolved = Bundle.localized.localizedString(forKey: key, value: "__MISSING__", table: nil)
        if resolved != "__MISSING__" { return resolved }
        return LegacyStrings.table[currentLanguage]?[key]
            ?? LegacyStrings.table[.english]?[key]
            ?? key
    }
}

/// Hardcoded legacy strings copied from the old in-code translation dictionaries.
/// Only consulted when a key isn't in the String Catalog. Schedule for removal once
/// all view sites have been migrated to `L10n`.
private enum LegacyStrings {
    static let table: [AppLanguage: [String: String]] = [
        .english: english,
        .arabic:  arabic,
        .hebrew:  hebrew
    ]

    static let english: [String: String] = [
        "dashboard": "Dashboard", "jobs": "Jobs", "contractors": "Contractors",
        "myOffers": "My Offers", "profile": "Profile", "manageProfile": "Manage Profile",
        "rating": "Rating", "completedJobs": "Completed Jobs",
        "availableForWork": "Available for Work", "bio": "Bio",
        "skills": "Skills", "contactInfo": "Contact Info", "portfolio": "Portfolio",
        "email": "Email", "phone": "Phone", "website": "Website",
        "location": "Location", "save": "Save", "edit": "Edit",
        "welcome": "Welcome to Shaglni", "tagline": "Connect with skilled contractors or find job opportunities",
        "login": "Login", "register": "Register", "signIn": "Sign In", "signUp": "Sign Up",
        "logout": "Logout", "getStarted": "Get Started",
        "alreadyHaveAccount": "Already have an account?", "selectRole": "Select Your Role",
        "jobPoster": "Job Poster", "contractor": "Contractor",
        "displayName": "Full Name", "password": "Password",
        "postJob": "Post a Job", "findContractor": "Find a Contractor",
        "price": "Price", "message": "Message", "category": "Category",
        "title": "Title", "description": "Description", "budget": "Budget",
        "submitOffer": "Submit Offer", "viewDetails": "View Details",
        "acceptOffer": "Accept Offer", "declineOffer": "Decline Offer",
        "open": "Open", "inProgress": "In Progress", "completed": "Completed",
        "pending": "Pending", "accepted": "Accepted", "rejected": "Declined",
        "browseJobs": "Browse Jobs", "myActiveJobs": "My Active Jobs",
        "myPortfolio": "My Portfolio", "noJobs": "No jobs yet",
        "noOffers": "No offers yet", "noContractors": "No contractors found"
    ]

    static let arabic: [String: String] = [
        "dashboard": "لوحة التحكم", "jobs": "الوظائف", "contractors": "المقاولون",
        "myOffers": "عروضي", "profile": "الملف الشخصي", "manageProfile": "إدارة الملف الشخصي",
        "rating": "التقييم", "completedJobs": "الأعمال المكتملة",
        "availableForWork": "متاح للعمل", "bio": "نبذة تعريفية",
        "skills": "المهارات", "contactInfo": "معلومات الاتصال", "portfolio": "معرض الأعمال",
        "email": "البريد الإلكتروني", "phone": "الهاتف", "website": "الموقع الإلكتروني",
        "location": "الموقع", "save": "حفظ", "edit": "تعديل",
        "welcome": "مرحباً بك في شغلني", "tagline": "تواصل مع مقاولين محترفين أو ابحث عن فرص عمل",
        "login": "تسجيل الدخول", "register": "إنشاء حساب",
        "signIn": "تسجيل الدخول", "signUp": "إنشاء حساب",
        "logout": "تسجيل الخروج", "getStarted": "ابدأ الآن",
        "alreadyHaveAccount": "لديك حساب بالفعل؟", "selectRole": "اختر دورك",
        "jobPoster": "صاحب عمل", "contractor": "مقاول",
        "displayName": "الاسم الكامل", "password": "كلمة المرور",
        "postJob": "نشر وظيفة", "findContractor": "البحث عن مقاول",
        "price": "السعر", "message": "الرسالة", "category": "الفئة",
        "title": "العنوان", "description": "الوصف", "budget": "الميزانية",
        "submitOffer": "تقديم عرض", "viewDetails": "عرض التفاصيل",
        "acceptOffer": "قبول العرض", "declineOffer": "رفض العرض",
        "open": "مفتوح", "inProgress": "قيد التنفيذ", "completed": "مكتمل",
        "pending": "قيد الانتظار", "accepted": "مقبول", "rejected": "مرفوض",
        "browseJobs": "تصفح الوظائف", "myActiveJobs": "أعمالي النشطة",
        "myPortfolio": "معرض أعمالي", "noJobs": "لا توجد وظائف بعد",
        "noOffers": "لا توجد عروض بعد", "noContractors": "لم يتم العثور على مقاولين"
    ]

    static let hebrew: [String: String] = [
        "dashboard": "לוח בקרה", "jobs": "משרות", "contractors": "קבלנים",
        "myOffers": "ההצעות שלי", "profile": "פרופיל", "manageProfile": "נהל פרופיל",
        "rating": "דירוג", "completedJobs": "עבודות שהושלמו",
        "availableForWork": "זמין לעבודה", "bio": "אודות",
        "skills": "כישורים", "contactInfo": "פרטי התקשרות", "portfolio": "תיק עבודות",
        "email": "אימייל", "phone": "טלפון", "website": "אתר אינטרנט",
        "location": "מיקום", "save": "שמור", "edit": "ערוך",
        "welcome": "ברוכים הבאים לשגלני", "tagline": "התחבר לקבלנים מיומנים או מצא הזדמנויות עבודה",
        "login": "התחברות", "register": "הרשמה",
        "signIn": "התחבר", "signUp": "הירשם",
        "logout": "התנתקות", "getStarted": "התחל",
        "alreadyHaveAccount": "כבר יש לך חשבון?", "selectRole": "בחר את התפקיד שלך",
        "jobPoster": "מפרסם משרות", "contractor": "קבלן",
        "displayName": "שם מלא", "password": "סיסמה",
        "postJob": "פרסם משרה", "findContractor": "מצא קבלן",
        "price": "מחיר", "message": "הודעה", "category": "קטגוריה",
        "title": "כותרת", "description": "תיאור", "budget": "תקציב",
        "submitOffer": "הגש הצעה", "viewDetails": "צפה בפרטים",
        "acceptOffer": "קבל את ההצעה", "declineOffer": "דחה את ההצעה",
        "open": "פתוח", "inProgress": "בתהליך", "completed": "הושלם",
        "pending": "ממתין", "accepted": "התקבל", "rejected": "נדחה",
        "browseJobs": "עיין במשרות", "myActiveJobs": "העבודות הפעילות שלי",
        "myPortfolio": "תיק העבודות שלי", "noJobs": "אין עדיין משרות",
        "noOffers": "אין עדיין הצעות", "noContractors": "לא נמצאו קבלנים"
    ]
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

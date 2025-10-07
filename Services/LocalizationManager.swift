//
//  LocalizationManager.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case arabic = "ar"
    case hebrew = "he"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        case .hebrew: return "עברית"
        }
    }
    
    var isRTL: Bool {
        self == .arabic || self == .hebrew
    }
}

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
        }
    }
    
    var isRTL: Bool {
        currentLanguage.isRTL
    }
    
    init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            self.currentLanguage = .arabic // Default to Arabic
        }
    }
    
    func localized(_ key: String) -> String {
        // In a real app, load from Localizable.strings files
        // For now, returning basic translations
        let translations: [AppLanguage: [String: String]] = [
            .english: englishTranslations,
            .arabic: arabicTranslations,
            .hebrew: hebrewTranslations
        ]
        
        return translations[currentLanguage]?[key] ?? key
    }
    
    private var englishTranslations: [String: String] {
        [
            "app.name": "Shaglni",
            "welcome": "Welcome to Shaglni",
            "tagline": "Connect with skilled contractors or find job opportunities",
            "login": "Login",
            "register": "Register",
            "email": "Email",
            "password": "Password",
            "displayName": "Full Name",
            "dashboard": "Dashboard",
            "jobs": "Jobs",
            "contractors": "Contractors",
            "profile": "Profile",
            "logout": "Logout",
            "postJob": "Post a Job",
            "findContractor": "Find a Contractor",
            "browseJobs": "Browse Jobs",
            "myOffers": "My Offers",
            "manageProfile": "Manage Profile",
            "jobPoster": "Job Poster",
            "contractor": "Contractor",
            "selectRole": "Select Your Role",
            "open": "Open",
            "inProgress": "In Progress",
            "completed": "Completed",
            "pending": "Pending",
            "accepted": "Accepted",
            "rejected": "Rejected",
            "submit": "Submit",
            "cancel": "Cancel",
            "save": "Save",
            "edit": "Edit",
            "delete": "Delete",
            "viewDetails": "View Details",
            "submitOffer": "Submit Offer",
            "price": "Price",
            "message": "Message",
            "location": "Location",
            "category": "Category",
            "budget": "Budget",
            "description": "Description",
            "title": "Title",
            "skills": "Skills",
            "rating": "Rating",
            "completedJobs": "Completed Jobs",
            "availableForWork": "Available for Work",
            "contactInfo": "Contact Information",
            "phone": "Phone",
            "website": "Website",
            "bio": "Bio",
            "portfolio": "Portfolio",
            "getStarted": "Get Started",
            "alreadyHaveAccount": "Already have an account?",
            "dontHaveAccount": "Don't have an account?",
            "signUp": "Sign Up",
            "signIn": "Sign In"
        ]
    }
    
    private var arabicTranslations: [String: String] {
        [
            "app.name": "شغلني",
            "welcome": "مرحباً بك في شغلني",
            "tagline": "تواصل مع مقاولين محترفين أو ابحث عن فرص عمل",
            "login": "تسجيل الدخول",
            "register": "إنشاء حساب",
            "email": "البريد الإلكتروني",
            "password": "كلمة المرور",
            "displayName": "الاسم الكامل",
            "dashboard": "لوحة التحكم",
            "jobs": "الوظائف",
            "contractors": "المقاولون",
            "profile": "الملف الشخصي",
            "logout": "تسجيل الخروج",
            "postJob": "نشر وظيفة",
            "findContractor": "البحث عن مقاول",
            "browseJobs": "تصفح الوظائف",
            "myOffers": "عروضي",
            "manageProfile": "إدارة الملف الشخصي",
            "jobPoster": "صاحب عمل",
            "contractor": "مقاول",
            "selectRole": "اختر دورك",
            "open": "مفتوح",
            "inProgress": "قيد التنفيذ",
            "completed": "مكتمل",
            "pending": "قيد الانتظار",
            "accepted": "مقبول",
            "rejected": "مرفوض",
            "submit": "إرسال",
            "cancel": "إلغاء",
            "save": "حفظ",
            "edit": "تعديل",
            "delete": "حذف",
            "viewDetails": "عرض التفاصيل",
            "submitOffer": "تقديم عرض",
            "price": "السعر",
            "message": "الرسالة",
            "location": "الموقع",
            "category": "الفئة",
            "budget": "الميزانية",
            "description": "الوصف",
            "title": "العنوان",
            "skills": "المهارات",
            "rating": "التقييم",
            "completedJobs": "الأعمال المكتملة",
            "availableForWork": "متاح للعمل",
            "contactInfo": "معلومات الاتصال",
            "phone": "الهاتف",
            "website": "الموقع الإلكتروني",
            "bio": "نبذة تعريفية",
            "portfolio": "معرض الأعمال",
            "getStarted": "ابدأ الآن",
            "alreadyHaveAccount": "لديك حساب بالفعل؟",
            "dontHaveAccount": "ليس لديك حساب؟",
            "signUp": "إنشاء حساب",
            "signIn": "تسجيل الدخول"
        ]
    }
    
    private var hebrewTranslations: [String: String] {
        [
            "app.name": "שגלני",
            "welcome": "ברוכים הבאים לשגלני",
            "tagline": "התחבר לקבלנים מיומנים או מצא הזדמנויות עבודה",
            "login": "התחברות",
            "register": "הרשמה",
            "email": "אימייל",
            "password": "סיסמה",
            "displayName": "שם מלא",
            "dashboard": "לוח בקרה",
            "jobs": "משרות",
            "contractors": "קבלנים",
            "profile": "פרופיל",
            "logout": "התנתקות",
            "postJob": "פרסם משרה",
            "findContractor": "מצא קבלן",
            "browseJobs": "עיין במשרות",
            "myOffers": "ההצעות שלי",
            "manageProfile": "נהל פרופיל",
            "jobPoster": "מפרסם משרות",
            "contractor": "קבלן",
            "selectRole": "בחר את התפקיד שלך",
            "open": "פתוח",
            "inProgress": "בתהליך",
            "completed": "הושלם",
            "pending": "ממתין",
            "accepted": "התקבל",
            "rejected": "נדחה",
            "submit": "שלח",
            "cancel": "ביטול",
            "save": "שמור",
            "edit": "ערוך",
            "delete": "מחק",
            "viewDetails": "צפה בפרטים",
            "submitOffer": "הגש הצעה",
            "price": "מחיר",
            "message": "הודעה",
            "location": "מיקום",
            "category": "קטגוריה",
            "budget": "תקציב",
            "description": "תיאור",
            "title": "כותרת",
            "skills": "כישורים",
            "rating": "דירוג",
            "completedJobs": "עבודות שהושלמו",
            "availableForWork": "זמין לעבודה",
            "contactInfo": "פרטי התקשרות",
            "phone": "טלפון",
            "website": "אתר אינטרנט",
            "bio": "אודות",
            "portfolio": "תיק עבודות",
            "getStarted": "התחל",
            "alreadyHaveAccount": "כבר יש לך חשבון?",
            "dontHaveAccount": "אין לך חשבון?",
            "signUp": "הירשם",
            "signIn": "התחבר"
        ]
    }
}

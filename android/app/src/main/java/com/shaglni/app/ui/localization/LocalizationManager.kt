package com.shaglni.app.ui.localization

import android.content.Context
import android.content.res.Configuration
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import java.util.Locale

object LocalizationManager {
    private var currentLocale: Locale by mutableStateOf(Locale.getDefault())
    
    fun setLocale(locale: Locale) {
        currentLocale = locale
    }
    
    fun getLocale(): Locale = currentLocale
    
    fun isRTL(): Boolean = currentLocale.language == "ar"
    
    fun localized(key: String): String {
        return when (key) {
            // App Info
            "app.name" -> if (isRTL()) "شغلني" else "Shaglni"
            "tagline" -> if (isRTL()) "ربط المقاولين بفرص العمل" else "Connect contractors with job opportunities"
            
            // Auth
            "welcome" -> if (isRTL()) "مرحباً" else "Welcome"
            "login" -> if (isRTL()) "تسجيل الدخول" else "Sign In"
            "signup" -> if (isRTL()) "إنشاء حساب" else "Sign Up"
            "email" -> if (isRTL()) "البريد الإلكتروني" else "Email"
            "password" -> if (isRTL()) "كلمة المرور" else "Password"
            "createAccount" -> if (isRTL()) "إنشاء حساب" else "Create Account"
            "alreadyHaveAccount" -> if (isRTL()) "لديك حساب بالفعل؟" else "Already have an account?"
            "dontHaveAccount" -> if (isRTL()) "ليس لديك حساب؟" else "Don't have an account?"
            "getStarted" -> if (isRTL()) "ابدأ الآن" else "Get Started"
            "signIn" -> if (isRTL()) "تسجيل الدخول" else "Sign In"
            "signUp" -> if (isRTL()) "إنشاء حساب" else "Sign Up"
            "welcomeBack" -> if (isRTL()) "مرحباً بعودتك" else "Welcome Back"
            "createYourAccount" -> if (isRTL()) "إنشاء حسابك" else "Create your account"
            "iAmA" -> if (isRTL()) "أنا:" else "I am a:"
            "contractor" -> if (isRTL()) "مقاول (يبحث عن عمل)" else "Contractor (looking for work)"
            "jobPoster" -> if (isRTL()) "صاحب عمل (يستأجر مقاولين)" else "Job Poster (hiring contractors)"
            
            // Navigation
            "dashboard" -> if (isRTL()) "الرئيسية" else "Dashboard"
            "jobs" -> if (isRTL()) "الوظائف" else "Jobs"
            "contractors" -> if (isRTL()) "المقاولون" else "Contractors"
            "myOffers" -> if (isRTL()) "عروضي" else "My Offers"
            "profile" -> if (isRTL()) "الملف الشخصي" else "Profile"
            
            // Jobs
            "jobDetails" -> if (isRTL()) "تفاصيل الوظيفة" else "Job Details"
            "description" -> if (isRTL()) "الوصف" else "Description"
            "location" -> if (isRTL()) "الموقع" else "Location"
            "datePosted" -> if (isRTL()) "تاريخ النشر" else "Date Posted"
            "postedBy" -> if (isRTL()) "نشر بواسطة" else "Posted by"
            "submitOffer" -> if (isRTL()) "تقديم عرض" else "Submit Offer"
            "searchJobs" -> if (isRTL()) "البحث في الوظائف..." else "Search jobs..."
            "createJob" -> if (isRTL()) "إنشاء وظيفة" else "Create Job"
            "postJob" -> if (isRTL()) "نشر وظيفة" else "Post Job"
            "jobsMap" -> if (isRTL()) "خريطة الوظائف" else "Jobs Map"
            "noJobsOnMap" -> if (isRTL()) "لا توجد وظائف على الخريطة" else "No jobs on map"
            "noJobsWithLocation" -> if (isRTL()) "لا توجد وظائف ببيانات موقع متاحة" else "No jobs with location data available"
            "tapToSelectLocation" -> if (isRTL()) "اضغط لاختيار الموقع" else "Tap to select location"
            "selectedLocation" -> if (isRTL()) "الموقع المحدد" else "Selected Location"
            "showMap" -> if (isRTL()) "إظهار الخريطة" else "Show Map"
            
            // Offers
            "offers" -> if (isRTL()) "العروض" else "Offers"
            "offerDetails" -> if (isRTL()) "تفاصيل العرض" else "Offer Details"
            "yourOffer" -> if (isRTL()) "عرضك" else "Your Offer"
            "price" -> if (isRTL()) "السعر" else "Price"
            "message" -> if (isRTL()) "الرسالة" else "Message"
            "optional" -> if (isRTL()) "(اختياري)" else "(optional)"
            "pending" -> if (isRTL()) "معلق" else "Pending"
            "accepted" -> if (isRTL()) "مقبول" else "Accepted"
            "rejected" -> if (isRTL()) "مرفوض" else "Rejected"
            "counterOffer" -> if (isRTL()) "عرض مضاد" else "Counter Offer"
            "all" -> if (isRTL()) "الكل" else "All"
            
            // Status
            "open" -> if (isRTL()) "مفتوح" else "Open"
            "inProgress" -> if (isRTL()) "قيد التنفيذ" else "In Progress"
            "completed" -> if (isRTL()) "مكتمل" else "Completed"
            "cancelled" -> if (isRTL()) "ملغي" else "Cancelled"
            
            // Dashboard
            "totalJobs" -> if (isRTL()) "إجمالي الوظائف" else "Total Jobs"
            "openJobs" -> if (isRTL()) "الوظائف المفتوحة" else "Open Jobs"
            "totalOffers" -> if (isRTL()) "إجمالي العروض" else "Total Offers"
            "pendingOffers" -> if (isRTL()) "العروض المعلقة" else "Pending Offers"
            "acceptedOffers" -> if (isRTL()) "العروض المقبولة" else "Accepted Offers"
            "completedJobs" -> if (isRTL()) "الوظائف المكتملة" else "Completed Jobs"
            "recentJobs" -> if (isRTL()) "الوظائف الأخيرة" else "Recent Jobs"
            "recentOffers" -> if (isRTL()) "العروض الأخيرة" else "Recent Offers"
            
            // Profile
            "settings" -> if (isRTL()) "الإعدادات" else "Settings"
            "signOut" -> if (isRTL()) "تسجيل الخروج" else "Sign Out"
            "signOutConfirm" -> if (isRTL()) "هل أنت متأكد من تسجيل الخروج؟" else "Are you sure you want to sign out?"
            "cancel" -> if (isRTL()) "إلغاء" else "Cancel"
            "version" -> if (isRTL()) "الإصدار" else "Version"
            
            // Common
            "loading" -> if (isRTL()) "جاري التحميل..." else "Loading..."
            "error" -> if (isRTL()) "خطأ" else "Error"
            "success" -> if (isRTL()) "نجح" else "Success"
            "today" -> if (isRTL()) "اليوم" else "Today"
            "yesterday" -> if (isRTL()) "أمس" else "Yesterday"
            "daysAgo" -> if (isRTL()) "أيام مضت" else "days ago"
            "hoursAgo" -> if (isRTL()) "ساعات مضت" else "hours ago"
            "justNow" -> if (isRTL()) "الآن" else "Just now"
            
            // Empty States
            "noJobsFound" -> if (isRTL()) "لم يتم العثور على وظائف" else "No jobs found"
            "noOffersFound" -> if (isRTL()) "لم يتم العثور على عروض" else "No offers found"
            "noJobsYet" -> if (isRTL()) "لا توجد وظائف بعد" else "No jobs yet"
            "noOffersYet" -> if (isRTL()) "لا توجد عروض بعد" else "No offers yet"
            "beFirstToPost" -> if (isRTL()) "كن أول من ينشر وظيفة!" else "Be the first to post a job!"
            "submitOffersToJobs" -> if (isRTL()) "قدم عروضاً للوظائف التي تهمك" else "Submit offers to jobs you're interested in"
            "tryAdjustingFilters" -> if (isRTL()) "حاول تعديل المرشحات" else "Try adjusting your filters"
            "tryAdjustingSearch" -> if (isRTL()) "حاول تعديل البحث أو المرشحات" else "Try adjusting your search or filters"
            
            else -> key
        }
    }
}

@Composable
fun rememberLocalizationManager(): LocalizationManager {
    val context = LocalContext.current
    val configuration = LocalConfiguration.current
    
    return LocalizationManager
}

@Composable
fun isRTL(): Boolean {
    val configuration = LocalConfiguration.current
    return configuration.locales[0].language == "ar"
}

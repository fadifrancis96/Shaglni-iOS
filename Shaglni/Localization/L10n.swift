//
//  L10n.swift
//  Shaglni
//
//  Typed wrappers around the String Catalog. Use `L10n.welcome.text` in SwiftUI to get
//  a fully localized `Text` view, or `L10n.welcome.string` for a plain `String`.
//

import SwiftUI

/// Lightweight typed key into Localizable.xcstrings.
/// `Bundle.localized` is the active language bundle managed by `LocalizationManager`.
struct L10n {
    let key: String

    var string: String {
        Bundle.localized.localizedString(forKey: key, value: nil, table: nil)
    }

    var text: Text {
        // SwiftUI Text(LocalizedStringKey) doesn't support custom bundle, so we resolve to String here.
        Text(verbatim: string)
    }

    func format(_ args: CVarArg...) -> String {
        String(format: string, arguments: args)
    }
}

extension L10n {
    static let appName       = L10n(key: "app.name")
    static let welcome       = L10n(key: "welcome")
    static let tagline       = L10n(key: "tagline")

    enum Common {
        static let login              = L10n(key: "common.login")
        static let register           = L10n(key: "common.register")
        static let email              = L10n(key: "common.email")
        static let password           = L10n(key: "common.password")
        static let displayName        = L10n(key: "common.displayName")
        static let submit             = L10n(key: "common.submit")
        static let cancel             = L10n(key: "common.cancel")
        static let save               = L10n(key: "common.save")
        static let edit               = L10n(key: "common.edit")
        static let delete             = L10n(key: "common.delete")
        static let done               = L10n(key: "common.done")
        static let signIn             = L10n(key: "common.signIn")
        static let signUp             = L10n(key: "common.signUp")
        static let logout             = L10n(key: "common.logout")
        static let getStarted         = L10n(key: "common.getStarted")
        static let alreadyHaveAccount = L10n(key: "common.alreadyHaveAccount")
        static let next               = L10n(key: "common.next")
        static let back               = L10n(key: "common.back")
        static let optional           = L10n(key: "common.optional")
        static let error              = L10n(key: "common.error")
    }

    enum Tab {
        static let dashboard   = L10n(key: "tab.dashboard")
        static let jobs        = L10n(key: "tab.jobs")
        static let contractors = L10n(key: "tab.contractors")
        static let offers      = L10n(key: "tab.offers")
        static let chat        = L10n(key: "tab.chat")
        static let profile     = L10n(key: "tab.profile")
    }

    enum Role {
        static let jobPoster  = L10n(key: "role.jobPoster")
        static let contractor = L10n(key: "role.contractor")
        static let select     = L10n(key: "role.select")
    }

    enum JobStatus {
        static let open       = L10n(key: "jobStatus.open")
        static let inProgress = L10n(key: "jobStatus.inProgress")
        static let completed  = L10n(key: "jobStatus.completed")
    }

    enum OfferStatusL {
        static let pending      = L10n(key: "offerStatus.pending")
        static let accepted     = L10n(key: "offerStatus.accepted")
        static let rejected     = L10n(key: "offerStatus.rejected")
        static let counterOffer = L10n(key: "offerStatus.counterOffer")
    }

    enum Field {
        static let price             = L10n(key: "field.price")
        static let message           = L10n(key: "field.message")
        static let location          = L10n(key: "field.location")
        static let category          = L10n(key: "field.category")
        static let budget            = L10n(key: "field.budget")
        static let description       = L10n(key: "field.description")
        static let title             = L10n(key: "field.title")
        static let skills            = L10n(key: "field.skills")
        static let rating            = L10n(key: "field.rating")
        static let phone             = L10n(key: "field.phone")
        static let website           = L10n(key: "field.website")
        static let bio               = L10n(key: "field.bio")
        static let completedJobs     = L10n(key: "field.completedJobs")
        static let availableForWork  = L10n(key: "field.availableForWork")
        static let contactInfo       = L10n(key: "field.contactInfo")
        static let portfolio         = L10n(key: "field.portfolio")
    }

    enum Action {
        static let postJob          = L10n(key: "action.postJob")
        static let findContractor   = L10n(key: "action.findContractor")
        static let browseJobs       = L10n(key: "action.browseJobs")
        static let myOffers         = L10n(key: "action.myOffers")
        static let receivedOffers   = L10n(key: "action.receivedOffers")
        static let manageProfile    = L10n(key: "action.manageProfile")
        static let myActiveJobs     = L10n(key: "action.myActiveJobs")
        static let myPortfolio      = L10n(key: "action.myPortfolio")
        static let submitOffer      = L10n(key: "action.submitOffer")
        static let viewDetails      = L10n(key: "action.viewDetails")
        static let viewAll          = L10n(key: "action.viewAll")
        static let acceptOffer      = L10n(key: "action.acceptOffer")
        static let declineOffer     = L10n(key: "action.declineOffer")
        static let negotiate        = L10n(key: "action.negotiate")
        static let markInProgress   = L10n(key: "action.markInProgress")
        static let markDone         = L10n(key: "action.markDone")
        static let forgotPassword   = L10n(key: "action.forgotPassword")
        static let sendResetEmail   = L10n(key: "action.sendResetEmail")
        static let deleteAccount    = L10n(key: "action.deleteAccount")
    }

    enum Section {
        static let recentJobs     = L10n(key: "section.recentJobs")
        static let availableJobs  = L10n(key: "section.availableJobs")
        static let myRecentOffers = L10n(key: "section.myRecentOffers")
        static func offersCount(_ n: Int) -> String { L10n(key: "section.offersCount").format(n) }
    }

    enum Empty {
        static let noJobs              = L10n(key: "empty.noJobs")
        static let noJobsFound         = L10n(key: "empty.noJobsFound")
        static let postFirstJob        = L10n(key: "empty.postFirstJob")
        static let tryFilters          = L10n(key: "empty.tryFilters")
        static let noOffers            = L10n(key: "empty.noOffers")
        static let submitOffers        = L10n(key: "empty.submitOffers")
        static let noActiveJobs        = L10n(key: "empty.noActiveJobs")
        static let noActiveJobsSubtitle = L10n(key: "empty.noActiveJobsSubtitle")
        static let noContractors       = L10n(key: "empty.noContractors")
        static let tryAdjustSearch     = L10n(key: "empty.tryAdjustSearch")
        static let noChats             = L10n(key: "empty.noChats")
        static let noChatsSubtitle     = L10n(key: "empty.noChatsSubtitle")
    }

    enum Search {
        static let jobs        = L10n(key: "search.jobs")
        static let contractors = L10n(key: "search.contractors")
        static let location    = L10n(key: "search.location")
    }

    enum Filter {
        static let all = L10n(key: "filter.all")
    }

    enum Loading {
        static let account = L10n(key: "loading.account")
    }

    enum Auth {
        static let confirmDeleteTitle   = L10n(key: "auth.confirmDelete.title")
        static let confirmDeleteMessage = L10n(key: "auth.confirmDelete.message")
        static let resetEmailSent       = L10n(key: "auth.resetEmailSent")
        static let accountLoadFailedTitle   = L10n(key: "auth.accountLoadFailed.title")
        static let accountLoadFailedMessage = L10n(key: "auth.accountLoadFailed.message")
        static let verifyEmail          = L10n(key: "auth.verifyEmail")
        static let resendVerification   = L10n(key: "auth.resendVerification")
    }

    enum Chat {
        static let placeholder = L10n(key: "chat.placeholder")
    }
}

// MARK: - Status helpers

extension JobStatus {
    var localized: String {
        switch self {
        case .open:       return L10n.JobStatus.open.string
        case .inProgress: return L10n.JobStatus.inProgress.string
        case .completed:  return L10n.JobStatus.completed.string
        }
    }
}

extension OfferStatus {
    var localized: String {
        switch self {
        case .pending:      return L10n.OfferStatusL.pending.string
        case .accepted:     return L10n.OfferStatusL.accepted.string
        case .rejected:     return L10n.OfferStatusL.rejected.string
        case .counterOffer: return L10n.OfferStatusL.counterOffer.string
        }
    }
}

extension JobCategory {
    var localized: String {
        let key = "category.\(rawValue)"
        return Bundle.localized.localizedString(forKey: key, value: rawValue, table: nil)
    }
}

//
//  ProfileView.swift
//  Shaglni
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var sendingVerification = false
    @State private var verificationStatus: String?
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            List {
                userSection

                if !authViewModel.isEmailVerified, authViewModel.currentUser != nil {
                    verifyEmailSection
                }

                if authViewModel.isContractor {
                    contractorActions
                }
                if authViewModel.isJobPoster {
                    jobPosterActions
                }

                languageSection
                aboutSection
                accountActions
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgCanvas)
            .navigationTitle(L10n.Tab.profile.string)
            .alert(L10n.Common.logout.string, isPresented: $showLogoutAlert) {
                Button(L10n.Common.cancel.string, role: .cancel) {}
                Button(L10n.Common.logout.string, role: .destructive) { authViewModel.signOut() }
            }
            .alert(L10n.Auth.confirmDeleteTitle.string, isPresented: $showDeleteAlert) {
                Button(L10n.Common.cancel.string, role: .cancel) {}
                Button(L10n.Action.deleteAccount.string, role: .destructive) {
                    Task {
                        do { try await authViewModel.deleteAccount() }
                        catch { deleteError = error.localizedDescription }
                    }
                }
            } message: {
                Text(L10n.Auth.confirmDeleteMessage.string)
            }
            .alert(L10n.Common.error.string, isPresented: .constant(deleteError != nil), actions: {
                Button(L10n.Common.done.string) { deleteError = nil }
            }, message: { Text(deleteError ?? "") })
        }
    }

    // MARK: - Sections

    private var userSection: some View {
        Section {
            HStack(spacing: DS.Space.l) {
                DSAvatar(name: authViewModel.currentUserData?.displayName ?? "", size: 64)

                VStack(alignment: .leading, spacing: 5) {
                    Text(authViewModel.currentUserData?.displayName ?? "")
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)

                    if let email = authViewModel.currentUser?.email {
                        Text(email)
                            .font(.dsCaption)
                            .foregroundStyle(Color.inkMuted)
                    }

                    HStack(spacing: 6) {
                        if let role = authViewModel.currentUserData?.role {
                            DSTag(
                                title: role == .jobPoster ? L10n.Role.jobPoster.string : L10n.Role.contractor.string,
                                systemImage: role == .jobPoster ? "briefcase.fill" : "hammer.fill",
                                tint: .brand,
                                background: .brandSoft
                            )
                        }
                        if authViewModel.isEmailVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.success)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, DS.Space.s)
        }
    }

    private var verifyEmailSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DS.Space.s) {
                Label(L10n.Auth.verifyEmail.string, systemImage: "envelope.badge")
                    .font(.dsSub)
                    .foregroundStyle(Color.warning)
                if let verificationStatus {
                    Text(verificationStatus)
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkMuted)
                }
                Button {
                    sendingVerification = true
                    Task {
                        try? await authViewModel.resendVerificationEmail()
                        verificationStatus = L10n.Auth.resetEmailSent.string
                        sendingVerification = false
                    }
                } label: {
                    if sendingVerification {
                        ProgressView()
                    } else {
                        Text(L10n.Auth.resendVerification.string)
                            .font(.dsCaptionBold)
                            .foregroundStyle(Color.brand)
                    }
                }
            }
        }
    }

    private var contractorActions: some View {
        Section {
            NavigationLink { ManageProfileView() } label: {
                ProfileRow(title: L10n.Action.manageProfile.string, systemImage: "person.text.rectangle.fill", tint: .brand)
            }
            NavigationLink { MyOffersView() } label: {
                ProfileRow(title: L10n.Action.myOffers.string, systemImage: "tag.fill", tint: .accentWarm)
            }
            NavigationLink { MyPortfolioView() } label: {
                ProfileRow(title: L10n.Action.myPortfolio.string, systemImage: "photo.stack.fill", tint: .info)
            }
        }
    }

    private var jobPosterActions: some View {
        Section {
            NavigationLink { JobListView() } label: {
                ProfileRow(title: L10n.Tab.jobs.string, systemImage: "briefcase.fill", tint: .brand)
            }
            NavigationLink { ReceivedOffersView() } label: {
                ProfileRow(title: L10n.Action.receivedOffers.string, systemImage: "tray.full.fill", tint: .accentWarm)
            }
        }
    }

    private var languageSection: some View {
        Section(header: Text(L10n.ProfileUI.language.string)) {
            Picker(L10n.ProfileUI.language.string, selection: Binding(
                get: { localization.currentLanguage },
                set: { localization.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .tint(Color.brand)
        }
    }

    private var aboutSection: some View {
        Section(header: Text(L10n.ProfileUI.about.string)) {
            HStack {
                Text(L10n.ProfileUI.version.string)
                Spacer()
                Text("1.0.0").foregroundStyle(Color.inkMuted)
            }
            Link(destination: URL(string: "https://shaglni.com/privacy")!) {
                HStack {
                    Text(L10n.ProfileUI.privacy.string).foregroundStyle(Color.ink)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Color.inkFaint)
                }
            }
            Link(destination: URL(string: "https://shaglni.com/terms")!) {
                HStack {
                    Text(L10n.ProfileUI.terms.string).foregroundStyle(Color.ink)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Color.inkFaint)
                }
            }
        }
    }

    private var accountActions: some View {
        Section {
            Button { showLogoutAlert = true } label: {
                HStack {
                    Spacer()
                    Text(L10n.Common.logout.string)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.danger)
                    Spacer()
                }
            }
            Button { showDeleteAlert = true } label: {
                HStack {
                    Spacer()
                    Text(L10n.Action.deleteAccount.string)
                        .font(.dsSub)
                        .foregroundStyle(Color.danger.opacity(0.8))
                    Spacer()
                }
            }
        }
    }
}

/// Standard settings row: tinted icon bubble + title.
private struct ProfileRow: View {
    let title: String
    let systemImage: String
    var tint: Color = .brand

    var body: some View {
        HStack(spacing: DS.Space.m) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                        .fill(tint.opacity(0.13))
                )
            Text(title)
                .font(.dsSub)
                .foregroundStyle(Color.ink)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
}

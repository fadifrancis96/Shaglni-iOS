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
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "person.fill").font(.title).foregroundColor(.accentColor))

                VStack(alignment: .leading, spacing: 4) {
                    if let userName = authViewModel.currentUserData?.displayName {
                        Text(userName).font(.headline)
                    }
                    if let email = authViewModel.currentUser?.email {
                        Text(email).font(.caption).foregroundColor(.secondary)
                    }
                    if let role = authViewModel.currentUserData?.role {
                        Text(role == .jobPoster ? L10n.Role.jobPoster.string : L10n.Role.contractor.string)
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var verifyEmailSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label(L10n.Auth.verifyEmail.string, systemImage: "envelope.badge")
                    .font(.subheadline)
                if let verificationStatus {
                    Text(verificationStatus).font(.caption).foregroundStyle(.secondary)
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
                        L10n.Auth.resendVerification.text
                    }
                }
            }
        }
    }

    private var contractorActions: some View {
        Section {
            NavigationLink {
                ManageProfileView()
            } label: {
                Label(L10n.Action.manageProfile.string, systemImage: "person.text.rectangle")
            }
            NavigationLink {
                MyOffersView()
            } label: {
                Label(L10n.Action.myOffers.string, systemImage: "doc.text")
            }
            NavigationLink {
                MyPortfolioView()
            } label: {
                Label(L10n.Action.myPortfolio.string, systemImage: "photo.stack")
            }
        }
    }

    private var jobPosterActions: some View {
        Section {
            NavigationLink {
                JobListView()
            } label: {
                Label(L10n.Tab.jobs.string, systemImage: "briefcase")
            }
            NavigationLink {
                ReceivedOffersView()
            } label: {
                Label(L10n.Action.receivedOffers.string, systemImage: "tray.full")
            }
        }
    }

    private var languageSection: some View {
        Section(header: Text(L10n(key: "profile.language").string)) {
            Picker(L10n(key: "profile.language").string, selection: Binding(
                get: { localization.currentLanguage },
                set: { localization.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section(header: Text(L10n(key: "profile.about").string)) {
            HStack { Text(L10n(key: "profile.version").string); Spacer(); Text("1.0.0").foregroundStyle(.secondary) }
            Link(destination: URL(string: "https://shaglni.com/privacy")!) {
                HStack {
                    Text(L10n(key: "profile.privacyPolicy").string)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
                }
            }
            Link(destination: URL(string: "https://shaglni.com/terms")!) {
                HStack {
                    Text(L10n(key: "profile.termsOfService").string)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var accountActions: some View {
        Section {
            Button { showLogoutAlert = true } label: {
                HStack {
                    Spacer()
                    L10n.Common.logout.text.foregroundColor(.red)
                    Spacer()
                }
            }
            Button { showDeleteAlert = true } label: {
                HStack {
                    Spacer()
                    L10n.Action.deleteAccount.text.foregroundColor(.red)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
}

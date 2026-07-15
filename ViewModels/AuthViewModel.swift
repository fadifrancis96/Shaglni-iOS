//
//  AuthViewModel.swift
//  Shaglni
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Single source of truth for the signed-in user and their role.
/// Owns Firestore listeners on Jobs/Offers/Contractors that depend on identity, so
/// switching accounts cleanly re-targets the live data.
@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var currentUser: FirebaseAuth.User?
    @Published private(set) var currentUserData: UserData?
    @Published private(set) var isBootstrapping = true
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userDocListener: ListenerRegistration?

    init() {
        observeAuthState()
    }

    deinit { if let authHandle { Auth.auth().removeStateDidChangeListener(authHandle) } }

    var isJobPoster:   Bool { currentUserData?.role == .jobPoster }
    var isContractor:  Bool { currentUserData?.role == .contractor }
    var isAuthenticated: Bool { currentUser != nil }
    /// True only after we know the user AND their role document. Use this to gate the main UI.
    var isReady: Bool { currentUser != nil && currentUserData != nil }

    // MARK: - Auth state

    private func observeAuthState() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                await self.handleAuthChange(user: user)
            }
        }
    }

    private func handleAuthChange(user: FirebaseAuth.User?) async {
        currentUser = user
        userDocListener?.remove()
        userDocListener = nil

        guard let user else {
            currentUserData = nil
            isBootstrapping = false
            stopAllListeners()
            return
        }

        // Live user document so role / displayName changes propagate.
        userDocListener = db.collection("users").document(user.uid)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                Task { @MainActor in
                    if let error = error {
                        AppLogger.auth.error("user doc listener: \(error.localizedDescription, privacy: .public)")
                    }
                    if let snap, snap.exists {
                        self.currentUserData = try? snap.data(as: UserData.self)
                    }
                    self.isBootstrapping = false
                    self.startListenersForRole()
                }
            }
    }

    private func startListenersForRole() {
        guard let uid = currentUser?.uid, let role = currentUserData?.role else { return }
        switch role {
        case .jobPoster:
            JobsRepository.shared.observePostedJobs(by: uid)
        case .contractor:
            JobsRepository.shared.observeOpenJobs()
            JobsRepository.shared.observeActiveJobs(for: uid)
            OffersRepository.shared.observeMyOffers(contractorId: uid)
            ContractorsRepository.shared.observeMyProfile(userId: uid)
            PortfolioRepository.shared.observeMyPortfolio(contractorId: uid)
        }
        ChatRepository.shared.observeThreads(for: uid)
        ContractorsRepository.shared.observeAllContractors()
    }

    private func stopAllListeners() {
        JobsRepository.shared.stopAll()
        OffersRepository.shared.stopObservingMyOffers()
        ContractorsRepository.shared.stopAll()
        PortfolioRepository.shared.stopObservingMyPortfolio()
        ChatRepository.shared.stopObservingThreads()
    }

    // MARK: - Sign in / sign up

    func signIn(email: String, password: String) async throws {
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw AppError.network(error.localizedDescription)
        }
    }

    func signUp(email: String, password: String, displayName: String, role: UserRole) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            try await result.user.sendEmailVerification()

            let user = UserData(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                role: role,
                createdAt: Date()
            )
            try db.collection("users").document(result.user.uid).setData(from: user)

            if role == .contractor {
                let profile = ContractorProfile(
                    userId: result.user.uid,
                    displayName: displayName,
                    bio: "",
                    skills: [],
                    rating: nil,
                    completedJobsCount: 0,
                    availableForWork: true
                )
                try await ContractorsRepository.shared.upsertProfile(profile)
            }
        } catch {
            throw AppError.network(error.localizedDescription)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    // MARK: - Password reset

    func sendPasswordReset(to email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            // For privacy we still surface a generic success message in the UI.
            AppLogger.auth.error("password reset failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Email verification

    var isEmailVerified: Bool { currentUser?.isEmailVerified ?? false }

    func resendVerificationEmail() async throws {
        try await currentUser?.sendEmailVerification()
    }

    func reloadVerificationStatus() async {
        try? await currentUser?.reload()
        objectWillChange.send()
    }

    // MARK: - Account deletion

    /// Best-effort delete: removes Firestore docs the user authored, then the auth user.
    /// Storage files are tied to security rules — Firebase deletes them automatically
    /// only if a Cloud Function listens for `users/{uid}` removals.
    func deleteAccount() async throws {
        guard let user = currentUser else { throw AppError.notAuthenticated }
        let uid = user.uid

        // 1. Remove user-owned Firestore documents we know about.
        try? await db.collection("contractorProfiles").document(uid).delete()

        let postedJobs = try await db.collection("jobs").whereField("createdBy", isEqualTo: uid).getDocuments()
        for doc in postedJobs.documents {
            try? await JobsRepository.shared.delete(jobId: doc.documentID)
        }

        try? await db.collection("users").document(uid).delete()

        // 2. Delete the Firebase Auth account.
        do {
            try await user.delete()
        } catch {
            // Most common reason: requires recent login. Surface to caller so they can
            // re-prompt the password and retry.
            throw AppError.network(error.localizedDescription)
        }
    }
}

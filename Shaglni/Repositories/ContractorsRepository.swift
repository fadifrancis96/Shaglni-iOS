//
//  ContractorsRepository.swift
//  Shaglni
//

import Foundation
import FirebaseFirestore

@MainActor
final class ContractorsRepository: ObservableObject {
    static let shared = ContractorsRepository()

    @Published private(set) var allContractors: [ContractorProfile] = []
    @Published private(set) var myProfile: ContractorProfile?

    private let db = Firestore.firestore()
    private var allContractorsListener: ListenerRegistration?
    private var myProfileListener: ListenerRegistration?

    private init() {}

    // MARK: - Listeners

    func observeAllContractors() {
        guard allContractorsListener == nil else { return }
        allContractorsListener = db.collection("contractorProfiles")
            .addSnapshotListener { [weak self] snap, error in
                if let error = error {
                    AppLogger.contractors.error("allContractors listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                self?.allContractors = snap?.decoded(as: ContractorProfile.self) ?? []
            }
    }

    func observeMyProfile(userId: String) {
        stopObservingMyProfile()
        myProfileListener = db.collection("contractorProfiles").document(userId)
            .addSnapshotListener { [weak self] snap, error in
                if let error = error {
                    AppLogger.contractors.error("myProfile listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                guard let snap, snap.exists else {
                    self?.myProfile = nil
                    return
                }
                self?.myProfile = try? snap.data(as: ContractorProfile.self)
            }
    }

    func stopObservingMyProfile() {
        myProfileListener?.remove()
        myProfileListener = nil
        myProfile = nil
    }

    func stopAll() {
        allContractorsListener?.remove()
        allContractorsListener = nil
        stopObservingMyProfile()
    }

    // MARK: - Mutations

    func fetchProfile(userId: String) async throws -> ContractorProfile {
        let snap = try await db.collection("contractorProfiles").document(userId).getDocument()
        return try snap.decode(as: ContractorProfile.self)
    }

    func upsertProfile(_ profile: ContractorProfile) async throws {
        guard let userId = profile.id ?? Optional(profile.userId) else {
            throw AppError.validation("Missing user id")
        }
        try db.collection("contractorProfiles").document(userId).setData(from: profile, merge: true)
        AppLogger.contractors.info("Upserted contractor profile \(userId, privacy: .public)")
    }

    func updateProfilePictureURL(userId: String, urlString: String) async throws {
        try await db.collection("contractorProfiles").document(userId).updateData([
            "profilePicture": urlString
        ])
    }

    func updateAvailability(userId: String, available: Bool) async throws {
        try await db.collection("contractorProfiles").document(userId).updateData([
            "availableForWork": available
        ])
    }

    func incrementCompletedJobsCount(contractorId: String) async throws {
        try await db.collection("contractorProfiles").document(contractorId).updateData([
            "completedJobsCount": FieldValue.increment(Int64(1))
        ])
    }

    func decrementCompletedJobsCount(contractorId: String) async throws {
        try await db.collection("contractorProfiles").document(contractorId).updateData([
            "completedJobsCount": FieldValue.increment(Int64(-1))
        ])
    }
}

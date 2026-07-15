//
//  PortfolioRepository.swift
//  Shaglni
//

import Foundation
import FirebaseFirestore

@MainActor
final class PortfolioRepository: ObservableObject {
    static let shared = PortfolioRepository()

    @Published private(set) var myPortfolio: [CompletedJob] = []

    private let db = Firestore.firestore()
    private var myPortfolioListener: ListenerRegistration?

    private init() {}

    // MARK: - Listeners

    func observeMyPortfolio(contractorId: String) {
        stopObservingMyPortfolio()
        myPortfolioListener = db.collection("completedJobs")
            .whereField("contractorId", isEqualTo: contractorId)
            .order(by: "completedDate", descending: true)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snap, error in
                if let error = error {
                    AppLogger.portfolio.error("myPortfolio listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                self?.myPortfolio = snap?.decoded(as: CompletedJob.self) ?? []
            }
    }

    func stopObservingMyPortfolio() {
        myPortfolioListener?.remove()
        myPortfolioListener = nil
        myPortfolio = []
    }

    // MARK: - Mutations

    /// Adds the portfolio entry and bumps the contractor's `completedJobsCount`
    /// in one batch so the counter can't drift from the actual portfolio size.
    @discardableResult
    func add(_ completedJob: CompletedJob) async throws -> String {
        let docRef = db.collection("completedJobs").document()
        let profileRef = db.collection("contractorProfiles").document(completedJob.contractorId)

        let batch = db.batch()
        try batch.setData(from: completedJob, forDocument: docRef)
        batch.updateData(["completedJobsCount": FieldValue.increment(Int64(1))], forDocument: profileRef)
        try await batch.commit()
        return docRef.documentID
    }

    func delete(_ completedJob: CompletedJob) async throws {
        guard let id = completedJob.id else { throw AppError.validation("Missing portfolio id") }
        let profileRef = db.collection("contractorProfiles").document(completedJob.contractorId)

        let batch = db.batch()
        batch.deleteDocument(db.collection("completedJobs").document(id))
        batch.updateData(["completedJobsCount": FieldValue.increment(Int64(-1))], forDocument: profileRef)
        try await batch.commit()
    }

    func fetchPortfolio(contractorId: String) async throws -> [CompletedJob] {
        let snap = try await db.collection("completedJobs")
            .whereField("contractorId", isEqualTo: contractorId)
            .order(by: "completedDate", descending: true)
            .limit(to: 100)
            .getDocuments()
        return snap.decoded(as: CompletedJob.self)
    }
}

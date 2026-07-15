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

    @discardableResult
    func add(_ completedJob: CompletedJob) async throws -> String {
        let ref = try db.collection("completedJobs").addDocument(from: completedJob)
        try? await ContractorsRepository.shared.incrementCompletedJobsCount(contractorId: completedJob.contractorId)
        return ref.documentID
    }

    func delete(_ completedJob: CompletedJob) async throws {
        guard let id = completedJob.id else { throw AppError.validation("Missing portfolio id") }
        try await db.collection("completedJobs").document(id).delete()
        try? await ContractorsRepository.shared.decrementCompletedJobsCount(contractorId: completedJob.contractorId)
    }

    func fetchPortfolio(contractorId: String) async throws -> [CompletedJob] {
        let snap = try await db.collection("completedJobs")
            .whereField("contractorId", isEqualTo: contractorId)
            .order(by: "completedDate", descending: true)
            .getDocuments()
        return snap.decoded(as: CompletedJob.self)
    }
}

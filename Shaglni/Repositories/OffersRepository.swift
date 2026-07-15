//
//  OffersRepository.swift
//  Shaglni
//

import Foundation
import FirebaseFirestore

@MainActor
final class OffersRepository: ObservableObject {
    static let shared = OffersRepository()

    /// Offers submitted by the active contractor (across all jobs).
    @Published private(set) var myOffers: [Offer] = []

    nonisolated private let db = Firestore.firestore()
    private var myOffersListener: ListenerRegistration?

    private init() {}

    // MARK: - Listeners

    /// Observe every offer authored by `contractorId` via collection-group query.
    /// Index required: `offers` (group), `contractorId` Asc + `createdAt` Desc.
    func observeMyOffers(contractorId: String) {
        stopObservingMyOffers()
        myOffersListener = db.collectionGroup("offers")
            .whereField("contractorId", isEqualTo: contractorId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    AppLogger.offers.error("myOffers listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                self?.myOffers = snapshot?.decoded(as: Offer.self) ?? []
            }
    }

    func stopObservingMyOffers() {
        myOffersListener?.remove()
        myOffersListener = nil
        myOffers = []
    }

    // MARK: - Per-job listener

    /// One-shot observable wrapper for offers under a single job.
    /// `onChange` is invoked on the main actor whenever the offers change.
    /// Returns a registration that callers should keep alive.
    nonisolated func listen(jobId: String, onChange: @escaping @MainActor ([Offer]) -> Void) -> ListenerRegistration {
        db.collection("jobs").document(jobId).collection("offers")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    AppLogger.offers.error("offers(jobId=\(jobId, privacy: .public)) listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                let offers = snapshot?.decoded(as: Offer.self) ?? []
                Task { @MainActor in onChange(offers) }
            }
    }

    /// One-shot fetch of all offers for a job. Use this when you don't need a live stream
    /// (e.g. computing dashboard counters).
    func fetchOffers(jobId: String) async throws -> [Offer] {
        let snap = try await db.collection("jobs").document(jobId).collection("offers")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snap.decoded(as: Offer.self)
    }

    // MARK: - Aggregate queries

    /// Returns every offer ever submitted to a particular job poster's jobs.
    /// Uses a `whereField("createdBy"...)` followed by per-job offer fetches.
    /// Cheap because we only hit jobs the user owns.
    func fetchOffersForJobPoster(_ posterId: String, jobs: [Job]) async throws -> [OfferWithJob] {
        try await withThrowingTaskGroup(of: [OfferWithJob].self) { group in
            for job in jobs {
                guard let jobId = job.id else { continue }
                group.addTask {
                    let offers = try await self.fetchOffers(jobId: jobId)
                    return offers.map { OfferWithJob(offer: $0, job: job) }
                }
            }
            var out: [OfferWithJob] = []
            for try await offers in group { out.append(contentsOf: offers) }
            out.sort { $0.offer.createdAt > $1.offer.createdAt }
            return out
        }
    }

    // MARK: - Mutations

    @discardableResult
    func submit(_ offer: Offer, jobId: String) async throws -> String {
        let ref = try db.collection("jobs").document(jobId).collection("offers").addDocument(from: offer)
        AppLogger.offers.info("Submitted offer \(ref.documentID, privacy: .public) on job \(jobId, privacy: .public)")
        return ref.documentID
    }

    func updateStatus(jobId: String, offerId: String, status: OfferStatus, extra: [String: Any] = [:]) async throws {
        var fields: [String: Any] = ["status": status.rawValue, "respondedAt": FieldValue.serverTimestamp()]
        fields.merge(extra) { _, new in new }
        try await db.collection("jobs").document(jobId).collection("offers").document(offerId).updateData(fields)
    }

    func sendCounterOffer(jobId: String, offerId: String, counterPrice: Double, message: String) async throws {
        try await updateStatus(jobId: jobId, offerId: offerId, status: .counterOffer, extra: [
            "counterPrice": counterPrice,
            "negotiationMessage": message
        ])
    }

    func contractorAcceptsCounter(jobId: String, offerId: String, finalPrice: Double) async throws {
        try await db.collection("jobs").document(jobId).collection("offers").document(offerId).updateData([
            "contractorAcceptedCounter": true,
            "finalPrice": finalPrice,
            "respondedAt": FieldValue.serverTimestamp()
        ])
    }

    func contractorDeclinesCounter(jobId: String, offerId: String) async throws {
        try await db.collection("jobs").document(jobId).collection("offers").document(offerId).delete()
    }

    /// Atomically: (1) accept this offer, (2) reject all others, (3) denormalise
    /// accepted offer fields onto the Job so my-active-jobs becomes a single query.
    func acceptOfferAndCloseOthers(jobId: String, acceptedOfferId: String, finalPrice: Double, contractorId: String) async throws {
        let batch = db.batch()
        let jobRef = db.collection("jobs").document(jobId)
        let offersCollection = jobRef.collection("offers")

        // Mark accepted
        let acceptedRef = offersCollection.document(acceptedOfferId)
        batch.updateData([
            "status": OfferStatus.accepted.rawValue,
            "finalPrice": finalPrice,
            "respondedAt": FieldValue.serverTimestamp()
        ], forDocument: acceptedRef)

        // Reject siblings (only ones that aren't already final)
        let siblingsSnap = try await offersCollection.getDocuments()
        for doc in siblingsSnap.documents where doc.documentID != acceptedOfferId {
            let status = doc.data()["status"] as? String
            if status == OfferStatus.pending.rawValue || status == OfferStatus.counterOffer.rawValue {
                batch.updateData([
                    "status": OfferStatus.rejected.rawValue,
                    "respondedAt": FieldValue.serverTimestamp()
                ], forDocument: doc.reference)
            }
        }

        // Denormalise onto the Job for fast queries
        batch.updateData([
            "acceptedOfferId": acceptedOfferId,
            "acceptedContractorId": contractorId,
            "acceptedPrice": finalPrice,
            "acceptedAt": FieldValue.serverTimestamp()
        ], forDocument: jobRef)

        try await batch.commit()
        AppLogger.offers.info("Accepted offer \(acceptedOfferId, privacy: .public) on job \(jobId, privacy: .public)")
    }
}

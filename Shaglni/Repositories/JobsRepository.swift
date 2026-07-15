//
//  JobsRepository.swift
//  Shaglni
//

import Foundation
import FirebaseFirestore

@MainActor
final class JobsRepository: ObservableObject {
    static let shared = JobsRepository()

    @Published private(set) var openJobs: [Job] = []
    @Published private(set) var myPostedJobs: [Job] = []
    @Published private(set) var myActiveJobs: [Job] = []     // contractor's accepted+inProgress+completed
    @Published private(set) var isLoadingOpenJobs = false

    private let db = Firestore.firestore()
    private var openJobsListener: ListenerRegistration?
    private var myPostedJobsListener: ListenerRegistration?
    private var myActiveJobsListener: ListenerRegistration?

    private init() {}

    // MARK: - Listeners

    /// Stream of all jobs that are still `open` — what contractors browse.
    func observeOpenJobs() {
        guard openJobsListener == nil else { return }
        isLoadingOpenJobs = true
        openJobsListener = db.collection("jobs")
            .whereField("status", isEqualTo: JobStatus.open.rawValue)
            .order(by: "datePosted", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoadingOpenJobs = false
                if let error = error {
                    AppLogger.jobs.error("openJobs listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                self.openJobs = snapshot?.decoded(as: Job.self) ?? []
            }
    }

    /// Stream of all jobs a particular user has posted.
    func observePostedJobs(by userId: String) {
        stopObservingPostedJobs()
        myPostedJobsListener = db.collection("jobs")
            .whereField("createdBy", isEqualTo: userId)
            .order(by: "datePosted", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    AppLogger.jobs.error("postedJobs listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                self?.myPostedJobs = snapshot?.decoded(as: Job.self) ?? []
            }
    }

    /// Stream of jobs the contractor has won (accepted offer denormalised on Job).
    /// A single query — no per-job offer fetch — thanks to denormalisation.
    func observeActiveJobs(for contractorId: String) {
        stopObservingActiveJobs()
        myActiveJobsListener = db.collection("jobs")
            .whereField("acceptedContractorId", isEqualTo: contractorId)
            .order(by: "acceptedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    AppLogger.jobs.error("activeJobs listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                self?.myActiveJobs = snapshot?.decoded(as: Job.self) ?? []
            }
    }

    func stopObservingPostedJobs() {
        myPostedJobsListener?.remove()
        myPostedJobsListener = nil
        myPostedJobs = []
    }

    func stopObservingActiveJobs() {
        myActiveJobsListener?.remove()
        myActiveJobsListener = nil
        myActiveJobs = []
    }

    func stopAll() {
        openJobsListener?.remove(); openJobsListener = nil
        stopObservingPostedJobs()
        stopObservingActiveJobs()
    }

    // MARK: - Mutations

    @discardableResult
    func create(_ job: Job) async throws -> String {
        let ref = try db.collection("jobs").addDocument(from: job)
        AppLogger.jobs.info("Created job \(ref.documentID, privacy: .public)")
        return ref.documentID
    }

    func update(jobId: String, fields: [String: Any]) async throws {
        try await db.collection("jobs").document(jobId).updateData(fields)
    }

    func updateStatus(jobId: String, status: JobStatus) async throws {
        var fields: [String: Any] = ["status": status.rawValue]
        if status == .completed { fields["completedAt"] = FieldValue.serverTimestamp() }
        try await update(jobId: jobId, fields: fields)
        AppLogger.jobs.info("Job \(jobId, privacy: .public) → \(status.rawValue, privacy: .public)")
    }

    func attachPhotoURLs(jobId: String, urls: [String]) async throws {
        try await update(jobId: jobId, fields: ["photoURLs": urls])
    }

    func fetch(jobId: String) async throws -> Job {
        let snap = try await db.collection("jobs").document(jobId).getDocument()
        return try snap.decode(as: Job.self)
    }

    /// Deletes the job and all of its offers in a single batch.
    /// NOTE: requirement photos in Storage are NOT removed here — the client may
    /// not outlive the operation. Orphan cleanup belongs in a Cloud Function
    /// triggered on job deletion.
    func delete(jobId: String) async throws {
        let jobRef = db.collection("jobs").document(jobId)
        let offersSnap = try await jobRef.collection("offers").getDocuments()

        let batch = db.batch()
        for doc in offersSnap.documents {
            batch.deleteDocument(doc.reference)
        }
        batch.deleteDocument(jobRef)
        try await batch.commit()
        AppLogger.jobs.info("Deleted job \(jobId, privacy: .public) with \(offersSnap.documents.count) offer(s)")
    }
}

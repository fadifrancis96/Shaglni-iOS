//
//  FirestoreService.swift
//  Shaglni
//
//  Compatibility shim that forwards every legacy callback-based API to the new
//  async repositories. New code should use the repositories directly (they expose
//  `@Published` arrays backed by live Firestore listeners — no polling needed).
//

import Foundation
import FirebaseFirestore

@MainActor
final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    private var jobs:        JobsRepository        { .shared }
    private var offers:      OffersRepository      { .shared }
    private var contractors: ContractorsRepository { .shared }
    private var portfolio:   PortfolioRepository   { .shared }

    // MARK: - Jobs

    func createJob(_ job: Job, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do { completion(.success(try await jobs.create(job))) }
            catch { completion(.failure(error)) }
        }
    }

    func fetchJobs(status: JobStatus? = nil, completion: @escaping (Result<[Job], Error>) -> Void) {
        Task {
            do {
                var query: Query = Firestore.firestore().collection("jobs")
                if let status { query = query.whereField("status", isEqualTo: status.rawValue) }
                let snap = try await query.order(by: "datePosted", descending: true)
                    .limit(to: JobsRepository.queryLimit).getDocuments()
                completion(.success(snap.decoded(as: Job.self)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchJobsByUser(userId: String, completion: @escaping (Result<[Job], Error>) -> Void) {
        Task {
            do {
                let snap = try await Firestore.firestore().collection("jobs")
                    .whereField("createdBy", isEqualTo: userId)
                    .order(by: "datePosted", descending: true)
                    .limit(to: JobsRepository.queryLimit)
                    .getDocuments()
                completion(.success(snap.decoded(as: Job.self)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func fetchJob(jobId: String, completion: @escaping (Result<Job, Error>) -> Void) {
        Task {
            do { completion(.success(try await jobs.fetch(jobId: jobId))) }
            catch { completion(.failure(error)) }
        }
    }

    func deleteJob(jobId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do { try await jobs.delete(jobId: jobId); completion(.success(())) }
            catch { completion(.failure(error)) }
        }
    }

    func updateJobStatus(jobId: String, status: JobStatus, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do { try await jobs.updateStatus(jobId: jobId, status: status); completion(.success(())) }
            catch { completion(.failure(error)) }
        }
    }

    // MARK: - Offers

    func submitOffer(_ offer: Offer, jobId: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do { completion(.success(try await offers.submit(offer, jobId: jobId))) }
            catch { completion(.failure(error)) }
        }
    }

    func fetchOffersForJob(jobId: String, completion: @escaping (Result<[Offer], Error>) -> Void) {
        Task {
            do { completion(.success(try await offers.fetchOffers(jobId: jobId))) }
            catch { completion(.failure(error)) }
        }
    }

    func fetchOffersByContractor(contractorId: String, completion: @escaping (Result<[Offer], Error>) -> Void) {
        Task {
            do {
                let snap = try await Firestore.firestore().collectionGroup("offers")
                    .whereField("contractorId", isEqualTo: contractorId)
                    .order(by: "createdAt", descending: true)
                    .limit(to: JobsRepository.queryLimit)
                    .getDocuments()
                completion(.success(snap.decoded(as: Offer.self)))
            } catch { completion(.failure(error)) }
        }
    }

    func fetchOffersForJobPoster(userId: String, completion: @escaping (Result<[OfferWithJob], Error>) -> Void) {
        Task {
            do {
                let myJobsSnap = try await Firestore.firestore().collection("jobs")
                    .whereField("createdBy", isEqualTo: userId)
                    .order(by: "datePosted", descending: true)
                    .limit(to: JobsRepository.queryLimit)
                    .getDocuments()
                let myJobs = myJobsSnap.decoded(as: Job.self)
                completion(.success(try await offers.fetchOffersForJobPoster(userId, jobs: myJobs)))
            } catch { completion(.failure(error)) }
        }
    }

    func updateOfferStatus(jobId: String, offerId: String, status: OfferStatus, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do { try await offers.updateStatus(jobId: jobId, offerId: offerId, status: status); completion(.success(())) }
            catch { completion(.failure(error)) }
        }
    }

    func sendCounterOffer(jobId: String, offerId: String, counterPrice: Double, message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do { try await offers.sendCounterOffer(jobId: jobId, offerId: offerId, counterPrice: counterPrice, message: message); completion(.success(())) }
            catch { completion(.failure(error)) }
        }
    }

    func respondToCounterOffer(jobId: String, offerId: String, accept: Bool, counterPrice: Double?, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                if accept {
                    guard let counterPrice, counterPrice > 0 else {
                        throw AppError.validation("Counter offer has no valid price")
                    }
                    try await offers.contractorAcceptsCounter(jobId: jobId, offerId: offerId, finalPrice: counterPrice)
                } else {
                    try await offers.contractorDeclinesCounter(jobId: jobId, offerId: offerId)
                }
                completion(.success(()))
            } catch { completion(.failure(error)) }
        }
    }

    // MARK: - Contractor Profiles

    func fetchContractorProfile(userId: String, completion: @escaping (Result<ContractorProfile, Error>) -> Void) {
        Task {
            do { completion(.success(try await contractors.fetchProfile(userId: userId))) }
            catch { completion(.failure(error)) }
        }
    }

    func fetchAllContractors(completion: @escaping (Result<[ContractorProfile], Error>) -> Void) {
        Task {
            do {
                let snap = try await Firestore.firestore().collection("contractorProfiles")
                    .order(by: "completedJobsCount", descending: true)
                    .limit(to: JobsRepository.queryLimit)
                    .getDocuments()
                completion(.success(snap.decoded(as: ContractorProfile.self)))
            } catch { completion(.failure(error)) }
        }
    }

    func updateContractorProfile(_ profile: ContractorProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do { try await contractors.upsertProfile(profile); completion(.success(())) }
            catch { completion(.failure(error)) }
        }
    }

    // MARK: - Completed Jobs

    func addCompletedJob(_ completedJob: CompletedJob, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do { completion(.success(try await portfolio.add(completedJob))) }
            catch { completion(.failure(error)) }
        }
    }

    func incrementCompletedJobsCount(contractorId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do { try await contractors.incrementCompletedJobsCount(contractorId: contractorId); completion(.success(())) }
            catch { completion(.failure(error)) }
        }
    }

    func fetchCompletedJobs(contractorId: String, completion: @escaping (Result<[CompletedJob], Error>) -> Void) {
        Task {
            do { completion(.success(try await portfolio.fetchPortfolio(contractorId: contractorId))) }
            catch { completion(.failure(error)) }
        }
    }

    func deleteCompletedJob(_ completedJob: CompletedJob, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do { try await portfolio.delete(completedJob); completion(.success(())) }
            catch { completion(.failure(error)) }
        }
    }

    func fetchJobsWithAcceptedOffer(contractorId: String, completion: @escaping (Result<[JobWithOffer], Error>) -> Void) {
        Task {
            do {
                let snap = try await Firestore.firestore().collection("jobs")
                    .whereField("acceptedContractorId", isEqualTo: contractorId)
                    .order(by: "acceptedAt", descending: true)
                    .limit(to: JobsRepository.queryLimit)
                    .getDocuments()
                let jobs = snap.decoded(as: Job.self)
                var out: [JobWithOffer] = []
                for j in jobs {
                    guard let jid = j.id, let oid = j.acceptedOfferId else { continue }
                    let offerDoc = try await Firestore.firestore().collection("jobs").document(jid).collection("offers").document(oid).getDocument()
                    if let off = try? offerDoc.decode(as: Offer.self) {
                        out.append(JobWithOffer(job: j, offer: off))
                    }
                }
                completion(.success(out))
            } catch { completion(.failure(error)) }
        }
    }
}

//
//  FirestoreService.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import FirebaseFirestore
import Combine

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Jobs
    
    func createJob(_ job: Job, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let docRef = try db.collection("jobs").addDocument(from: job)
            completion(.success(docRef.documentID))
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchJobs(status: JobStatus? = nil, completion: @escaping (Result<[Job], Error>) -> Void) {
        var query: Query = db.collection("jobs")
        
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        
        query.order(by: "datePosted", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching jobs: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found in jobs collection")
                    completion(.success([]))
                    return
                }
                
                print("📄 Found \(documents.count) job documents")
                let jobs = documents.compactMap { doc in
                    do {
                        let job = try doc.data(as: Job.self)
                        return job
                    } catch {
                        print("❌ Failed to parse job document \(doc.documentID): \(error.localizedDescription)")
                        return nil
                    }
                }
                print("✅ Successfully parsed \(jobs.count) jobs")
                completion(.success(jobs))
            }
    }
    
    func fetchJobsByUser(userId: String, completion: @escaping (Result<[Job], Error>) -> Void) {
        print("🔍 Fetching jobs for user: \(userId)")
        db.collection("jobs")
            .whereField("createdBy", isEqualTo: userId)
            .order(by: "datePosted", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching user jobs: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found for user \(userId)")
                    completion(.success([]))
                    return
                }
                
                print("📄 Found \(documents.count) job documents for user")
                let jobs = documents.compactMap { doc in
                    do {
                        let job = try doc.data(as: Job.self)
                        return job
                    } catch {
                        print("❌ Failed to parse job document \(doc.documentID): \(error.localizedDescription)")
                        return nil
                    }
                }
                print("✅ Successfully parsed \(jobs.count) user jobs")
                completion(.success(jobs))
            }
    }
    
    func fetchJob(jobId: String, completion: @escaping (Result<Job, Error>) -> Void) {
        db.collection("jobs").document(jobId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Job not found"])))
                return
            }
            
            do {
                let job = try snapshot.data(as: Job.self)
                completion(.success(job))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func deleteJob(jobId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🗑️ Deleting job: \(jobId)")
        
        // First, delete all offers associated with this job
        db.collection("jobs").document(jobId)
            .collection("offers")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching offers to delete: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                let group = DispatchGroup()
                var deleteErrors: [Error] = []
                
                // Delete all offers
                snapshot?.documents.forEach { document in
                    group.enter()
                    document.reference.delete { error in
                        if let error = error {
                            deleteErrors.append(error)
                        }
                        group.leave()
                    }
                }
                
                // After all offers are deleted, delete the job
                group.notify(queue: .main) {
                    if !deleteErrors.isEmpty {
                        print("❌ Error deleting offers: \(deleteErrors.first!.localizedDescription)")
                        completion(.failure(deleteErrors.first!))
                        return
                    }
                    
                    // Delete the job document
                    self.db.collection("jobs").document(jobId).delete { error in
                        if let error = error {
                            print("❌ Error deleting job: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("✅ Job deleted successfully")
                            completion(.success(()))
                        }
                    }
                }
            }
    }
    
    // MARK: - Offers
    
    func submitOffer(_ offer: Offer, jobId: String, completion: @escaping (Result<String, Error>) -> Void) {
        print("📝 Submitting offer for job: \(jobId)")
        print("   Contractor: \(offer.contractorId)")
        print("   Price: \(offer.price)")
        
        // First, get the job to find the job poster
        db.collection("jobs").document(jobId).getDocument { [weak self] jobSnapshot, error in
            guard let self = self else { return }
            
            do {
                let docRef = try self.db.collection("jobs").document(jobId)
                    .collection("offers").addDocument(from: offer)
                print("✅ Offer submitted successfully with ID: \(docRef.documentID)")
                
                // Send notification to job poster
                // TODO: Uncomment after adding FirebaseMessaging package to Xcode
                // if let jobData = jobSnapshot?.data(),
                //    let createdBy = jobData["createdBy"] as? String,
                //    let jobTitle = jobData["title"] as? String {
                //     PushNotificationService.shared.sendOfferNotification(
                //         to: createdBy,
                //         jobTitle: jobTitle,
                //         contractorName: offer.contractorName,
                //         price: offer.price
                //     )
                // }
                
                completion(.success(docRef.documentID))
            } catch {
                print("❌ Error submitting offer: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func fetchOffersForJob(jobId: String, completion: @escaping (Result<[Offer], Error>) -> Void) {
        db.collection("jobs").document(jobId)
            .collection("offers")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let offers = documents.compactMap { try? $0.data(as: Offer.self) }
                completion(.success(offers))
            }
    }
    
    func fetchOffersByContractor(contractorId: String, completion: @escaping (Result<[Offer], Error>) -> Void) {
        print("🔍 Fetching offers for contractor: \(contractorId)")
        db.collectionGroup("offers")
            .whereField("contractorId", isEqualTo: contractorId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching offers: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found")
                    completion(.success([]))
                    return
                }
                
                print("✅ Found \(documents.count) offers")
                let offers = documents.compactMap { try? $0.data(as: Offer.self) }
                print("✅ Successfully parsed \(offers.count) offers")
                completion(.success(offers))
            }
    }
    
    func updateOfferStatus(jobId: String, offerId: String, status: OfferStatus, completion: @escaping (Result<Void, Error>) -> Void) {
        print("📝 Updating offer status to: \(status.rawValue)")
        
        // First, get the offer to find the contractor
        db.collection("jobs").document(jobId)
            .collection("offers").document(offerId).getDocument { [weak self] offerSnapshot, error in
                guard let self = self else { return }
                
                self.db.collection("jobs").document(jobId)
                    .collection("offers").document(offerId)
                    .updateData([
                        "status": status.rawValue,
                        "respondedAt": Date()
                    ]) { error in
                        if let error = error {
                            print("❌ Error updating offer status: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("✅ Offer status updated successfully")
                            
                            // Send notification to contractor
                            // TODO: Uncomment after adding FirebaseMessaging package to Xcode
                            // if let offerData = offerSnapshot?.data(),
                            //    let contractorId = offerData["contractorId"] as? String {
                            //     self.db.collection("jobs").document(jobId).getDocument { jobSnapshot, _ in
                            //         if let jobTitle = jobSnapshot?.data()?["title"] as? String {
                            //             PushNotificationService.shared.sendOfferResponseNotification(
                            //                 to: contractorId,
                            //                 jobTitle: jobTitle,
                            //                 status: status
                            //             )
                            //         }
                            //     }
                            // }
                            
                            completion(.success(()))
                        }
                    }
            }
    }
    
    func sendCounterOffer(jobId: String, offerId: String, counterPrice: Double, message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("💰 Sending counter offer: ₪\(counterPrice)")
        
        // First, get the offer to find the contractor
        db.collection("jobs").document(jobId)
            .collection("offers").document(offerId).getDocument { [weak self] offerSnapshot, error in
                guard let self = self else { return }
                
                self.db.collection("jobs").document(jobId)
                    .collection("offers").document(offerId)
                    .updateData([
                        "status": OfferStatus.counterOffer.rawValue,
                        "counterPrice": counterPrice,
                        "negotiationMessage": message,
                        "respondedAt": Date()
                    ]) { error in
                        if let error = error {
                            print("❌ Error sending counter offer: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("✅ Counter offer sent successfully")
                            
                            // Send notification to contractor
                            // TODO: Uncomment after adding FirebaseMessaging package to Xcode
                            // if let offerData = offerSnapshot?.data(),
                            //    let contractorId = offerData["contractorId"] as? String {
                            //     self.db.collection("jobs").document(jobId).getDocument { jobSnapshot, _ in
                            //         if let jobTitle = jobSnapshot?.data()?["title"] as? String {
                            //             PushNotificationService.shared.sendOfferResponseNotification(
                            //                 to: contractorId,
                            //                 jobTitle: jobTitle,
                            //                 status: .counterOffer,
                            //                 counterPrice: counterPrice
                            //             )
                            //         }
                            //     }
                            // }
                            
                            completion(.success(()))
                        }
                    }
            }
    }
    
    func respondToCounterOffer(jobId: String, offerId: String, accept: Bool, counterPrice: Double?, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🔄 Responding to counter offer: \(accept ? "Accept" : "Decline")")
        
        if accept {
            // Contractor accepts the counter offer - mark as pending for job poster final approval
            var updateData: [String: Any] = [
                "contractorAcceptedCounter": true,
                "respondedAt": Date()
            ]
            
            // Set final price as counter price if available
            if let counterPrice = counterPrice {
                updateData["finalPrice"] = counterPrice
            }
            
            db.collection("jobs").document(jobId)
                .collection("offers").document(offerId)
                .updateData(updateData) { error in
                    if let error = error {
                        print("❌ Error accepting counter offer: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("✅ Contractor accepted counter offer - awaiting job poster approval")
                        completion(.success(()))
                    }
                }
        } else {
            // Decline the counter offer - delete the offer entirely
            db.collection("jobs").document(jobId)
                .collection("offers").document(offerId)
                .delete { error in
                    if let error = error {
                        print("❌ Error declining counter offer: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("✅ Counter offer declined and deleted successfully")
                        completion(.success(()))
                    }
                }
        }
    }
    
    func finalizeOffer(jobId: String, offerId: String, finalPrice: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        print("✅ Finalizing offer with price: ₪\(finalPrice)")
        
        db.collection("jobs").document(jobId)
            .collection("offers").document(offerId)
            .updateData([
                "status": OfferStatus.accepted.rawValue,
                "finalPrice": finalPrice,
                "respondedAt": Date()
            ]) { error in
                if let error = error {
                    print("❌ Error finalizing offer: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("✅ Offer finalized successfully")
                    completion(.success(()))
                }
            }
    }
    
    func updateJobStatus(jobId: String, status: JobStatus, completion: @escaping (Result<Void, Error>) -> Void) {
        print("🔄 Updating job status to: \(status.rawValue)")
        
        db.collection("jobs").document(jobId)
            .updateData([
                "status": status.rawValue
            ]) { error in
                if let error = error {
                    print("❌ Error updating job status: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("✅ Job status updated successfully to \(status.rawValue)")
                    completion(.success(()))
                }
            }
    }
    
    // MARK: - Contractor Profiles
    
    func fetchContractorProfile(userId: String, completion: @escaping (Result<ContractorProfile, Error>) -> Void) {
        db.collection("contractorProfiles").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])))
                return
            }
            
            do {
                let profile = try snapshot.data(as: ContractorProfile.self)
                completion(.success(profile))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func fetchAllContractors(completion: @escaping (Result<[ContractorProfile], Error>) -> Void) {
        db.collection("contractorProfiles")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let profiles = documents.compactMap { try? $0.data(as: ContractorProfile.self) }
                completion(.success(profiles))
            }
    }
    
    func updateContractorProfile(_ profile: ContractorProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = profile.userId as String? else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"])))
            return
        }
        
        do {
            try db.collection("contractorProfiles").document(userId).setData(from: profile, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Completed Jobs
    
    func addCompletedJob(_ completedJob: CompletedJob, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let docRef = try db.collection("completedJobs").addDocument(from: completedJob)
            completion(.success(docRef.documentID))
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchCompletedJobs(contractorId: String, completion: @escaping (Result<[CompletedJob], Error>) -> Void) {
        db.collection("completedJobs")
            .whereField("contractorId", isEqualTo: contractorId)
            .order(by: "completedDate", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let jobs = documents.compactMap { try? $0.data(as: CompletedJob.self) }
                completion(.success(jobs))
            }
    }
}

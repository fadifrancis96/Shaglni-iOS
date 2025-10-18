package com.shaglni.app.data

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.ListenerRegistration
import com.shaglni.app.data.model.CompletedJob
import com.shaglni.app.data.model.ContractorProfile
import com.shaglni.app.data.model.Job
import com.shaglni.app.data.model.Offer
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FirestoreService @Inject constructor() {
    private val db: FirebaseFirestore = FirebaseFirestore.getInstance()

    // Jobs
    suspend fun createJob(job: Job): String {
        val docRef = db.collection("jobs").add(job).await()
        return docRef.id
    }

    suspend fun fetchJobs(status: String? = null): List<Job> {
        var query: Query = db.collection("jobs")
        if (status != null) query = query.whereEqualTo("status", status)
        val snapshot = query.orderBy("datePosted", Query.Direction.DESCENDING).get().await()
        return snapshot.documents.mapNotNull { it.toObject(Job::class.java)?.copy(id = it.id) }
    }

    suspend fun fetchJobsByUser(userId: String): List<Job> {
        val snapshot = db.collection("jobs")
            .whereEqualTo("createdBy", userId)
            .orderBy("datePosted", Query.Direction.DESCENDING)
            .get().await()
        return snapshot.documents.mapNotNull { it.toObject(Job::class.java)?.copy(id = it.id) }
    }

    suspend fun fetchJob(jobId: String): Job? {
        val doc = db.collection("jobs").document(jobId).get().await()
        return if (doc.exists()) doc.toObject(Job::class.java)?.copy(id = doc.id) else null
    }

    suspend fun updateJob(job: Job) {
        require(job.id.isNotBlank()) { "Job ID is required for updates" }
        db.collection("jobs").document(job.id).set(job).await()
    }

    suspend fun deleteJob(jobId: String) {
        db.collection("jobs").document(jobId).delete().await()
    }

    // Offers
    suspend fun submitOffer(offer: Offer, jobId: String): String {
        val docRef = db.collection("jobs").document(jobId)
            .collection("offers").add(offer).await()
        return docRef.id
    }

    suspend fun fetchOffersForJob(jobId: String): List<Offer> {
        val snapshot = db.collection("jobs").document(jobId)
            .collection("offers")
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .get().await()
        return snapshot.documents.mapNotNull { it.toObject(Offer::class.java)?.copy(id = it.id, jobId = jobId) }
    }

    suspend fun fetchOffersByContractor(contractorId: String): List<Offer> {
        val snapshot = db.collectionGroup("offers")
            .whereEqualTo("contractorId", contractorId)
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .get().await()
        return snapshot.documents.mapNotNull {
            val jobId = it.reference.parent.parent?.id ?: ""
            it.toObject(Offer::class.java)?.copy(id = it.id, jobId = jobId)
        }
    }

    suspend fun updateOfferStatus(jobId: String, offerId: String, status: String) {
        db.collection("jobs").document(jobId)
            .collection("offers").document(offerId)
            .update(mapOf(
                "status" to status,
                "respondedAt" to com.google.firebase.Timestamp.now()
            )).await()
    }

    suspend fun sendCounterOffer(jobId: String, offerId: String, counterPrice: Double, message: String) {
        db.collection("jobs").document(jobId)
            .collection("offers").document(offerId)
            .update(mapOf(
                "status" to "counter_offer",
                "counterPrice" to counterPrice,
                "negotiationMessage" to message,
                "respondedAt" to com.google.firebase.Timestamp.now()
            )).await()
    }

    suspend fun respondToCounterOffer(jobId: String, offerId: String, accept: Boolean) {
        if (accept) {
            db.collection("jobs").document(jobId)
                .collection("offers").document(offerId)
                .update(mapOf(
                    "status" to "accepted",
                    "respondedAt" to com.google.firebase.Timestamp.now()
                )).await()
        } else {
            db.collection("jobs").document(jobId)
                .collection("offers").document(offerId)
                .delete().await()
        }
    }

    // Contractor Profiles
    suspend fun fetchContractorProfile(userId: String): ContractorProfile? {
        val doc = db.collection("contractorProfiles").document(userId).get().await()
        return if (doc.exists()) doc.toObject(ContractorProfile::class.java) else null
    }

    suspend fun fetchAllContractors(): List<ContractorProfile> {
        val snapshot = db.collection("contractorProfiles").get().await()
        return snapshot.documents.mapNotNull { it.toObject(ContractorProfile::class.java) }
    }

    suspend fun updateContractorProfile(profile: ContractorProfile) {
        require(profile.userId.isNotBlank()) { "Invalid user ID" }
        db.collection("contractorProfiles").document(profile.userId).set(profile).await()
    }

    // Completed Jobs
    suspend fun addCompletedJob(completedJob: CompletedJob): String {
        val docRef = db.collection("completedJobs").add(completedJob).await()
        return docRef.id
    }

    suspend fun fetchCompletedJobs(contractorId: String): List<CompletedJob> {
        val snapshot = db.collection("completedJobs")
            .whereEqualTo("contractorId", contractorId)
            .orderBy("completedDate", Query.Direction.DESCENDING)
            .get().await()
        return snapshot.documents.mapNotNull { it.toObject(CompletedJob::class.java)?.copy(id = it.id) }
    }

    // Real-time updates
    fun observeJobs(status: String? = null): Flow<List<Job>> = callbackFlow {
        var query: Query = db.collection("jobs")
        if (status != null) query = query.whereEqualTo("status", status)
        
        val listener = query.orderBy("datePosted", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val jobs = snapshot?.documents?.mapNotNull { 
                    it.toObject(Job::class.java)?.copy(id = it.id) 
                } ?: emptyList()
                
                trySend(jobs)
            }
        
        awaitClose { listener.remove() }
    }

    fun observeJobsByUser(userId: String): Flow<List<Job>> = callbackFlow {
        val listener = db.collection("jobs")
            .whereEqualTo("createdBy", userId)
            .orderBy("datePosted", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val jobs = snapshot?.documents?.mapNotNull { 
                    it.toObject(Job::class.java)?.copy(id = it.id) 
                } ?: emptyList()
                
                trySend(jobs)
            }
        
        awaitClose { listener.remove() }
    }

    fun observeOffersForJob(jobId: String): Flow<List<Offer>> = callbackFlow {
        val listener = db.collection("jobs").document(jobId)
            .collection("offers")
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val offers = snapshot?.documents?.mapNotNull { 
                    it.toObject(Offer::class.java)?.copy(id = it.id, jobId = jobId) 
                } ?: emptyList()
                
                trySend(offers)
            }
        
        awaitClose { listener.remove() }
    }

    fun observeOffersByContractor(contractorId: String): Flow<List<Offer>> = callbackFlow {
        val listener = db.collectionGroup("offers")
            .whereEqualTo("contractorId", contractorId)
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val offers = snapshot?.documents?.mapNotNull {
                    val jobId = it.reference.parent.parent?.id ?: ""
                    it.toObject(Offer::class.java)?.copy(id = it.id, jobId = jobId)
                } ?: emptyList()
                
                trySend(offers)
            }
        
        awaitClose { listener.remove() }
    }

    fun observeJob(jobId: String): Flow<Job?> = callbackFlow {
        val listener = db.collection("jobs").document(jobId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    close(error)
                    return@addSnapshotListener
                }
                
                val job = if (snapshot?.exists() == true) {
                    snapshot.toObject(Job::class.java)?.copy(id = snapshot.id)
                } else {
                    null
                }
                
                trySend(job)
            }
        
        awaitClose { listener.remove() }
    }
}



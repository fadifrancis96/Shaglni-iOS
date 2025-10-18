package com.shaglni.app.data.model

data class Offer(
    val id: String = "",
    val jobId: String = "",
    val contractorId: String = "",
    val contractorName: String = "",
    val message: String = "",
    val price: Double = 0.0,
    val status: String = "pending", // values: pending|accepted|rejected|counter_offer
    val createdAt: com.google.firebase.Timestamp? = null,
    val counterPrice: Double? = null,
    val negotiationMessage: String? = null,
    val respondedAt: com.google.firebase.Timestamp? = null
)




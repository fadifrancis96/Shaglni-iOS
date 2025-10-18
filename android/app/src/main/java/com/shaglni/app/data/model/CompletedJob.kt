package com.shaglni.app.data.model

data class CompletedJob(
    val id: String = "",
    val jobId: String = "",
    val contractorId: String = "",
    val contractorName: String = "",
    val title: String = "",
    val description: String = "",
    val location: String = "",
    val price: Double = 0.0,
    val completedDate: com.google.firebase.Timestamp? = null,
    val rating: Double? = null,
    val review: String? = null
)

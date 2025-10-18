package com.shaglni.app.data.model

data class Job(
    val id: String = "",
    val title: String = "",
    val description: String = "",
    val createdBy: String = "",
    val status: String = "open", // values: "open" | "closed"
    val datePosted: com.google.firebase.Timestamp? = null,
    val location: String = "",
    val latitude: Double? = null,
    val longitude: Double? = null,
    val category: String? = null,
    val budget: Double? = null
)




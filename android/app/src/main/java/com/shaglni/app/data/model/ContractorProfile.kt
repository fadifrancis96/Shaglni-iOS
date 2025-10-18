package com.shaglni.app.data.model

data class ContractorProfile(
    val userId: String = "",
    val displayName: String = "",
    val bio: String = "",
    val rating: Double? = null,
    val completedJobsCount: Int = 0,
    val skills: List<String> = emptyList(),
    val portfolioImages: List<String> = emptyList(),
    val contactEmail: String? = null,
    val phone: String? = null,
    val website: String? = null,
    val location: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val availableForWork: Boolean = true,
    val portfolio: List<String> = emptyList()
)



package com.shaglni.app.data.model

import com.google.firebase.Timestamp

data class User(
    val id: String = "",
    val email: String = "",
    val displayName: String = "",
    val role: UserRole = UserRole.Contractor,
    val createdAt: Timestamp? = null,
    val fcmToken: String? = null,
    val fcmTokenUpdatedAt: Timestamp? = null
)

enum class UserRole { JobPoster, Contractor }



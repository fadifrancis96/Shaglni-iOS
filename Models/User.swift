//
//  User.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case jobPoster = "job_poster"
    case contractor = "contractor"
}

struct UserData: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var role: UserRole
    var createdAt: Date
    var fcmToken: String?
    var fcmTokenUpdatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case role
        case createdAt
        case fcmToken
        case fcmTokenUpdatedAt
    }
}

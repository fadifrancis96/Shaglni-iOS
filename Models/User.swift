//
//  User.swift
//  Shaglni
//

import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case jobPoster  = "job_poster"
    case contractor = "contractor"
}

struct UserData: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var role: UserRole
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email, displayName, role, createdAt
    }
}

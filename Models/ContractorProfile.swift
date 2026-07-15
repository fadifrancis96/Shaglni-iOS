//
//  ContractorProfile.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import FirebaseFirestore
import CoreLocation

struct ContractorProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var displayName: String
    var bio: String
    var skills: [String]
    var rating: Double?
    var completedJobsCount: Int
    var contactEmail: String?
    var phone: String?
    var website: String?
    var profilePicture: String?
    var location: String?
    var latitude: Double?
    var longitude: Double?
    var availableForWork: Bool
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case displayName
        case bio
        case skills
        case rating
        case completedJobsCount
        case contactEmail
        case phone
        case website
        case profilePicture
        case location
        case latitude
        case longitude
        case availableForWork
    }
}

struct CompletedJob: Identifiable, Codable {
    @DocumentID var id: String?
    var contractorId: String
    var jobId: String?  // Reference to original job
    var title: String
    var description: String
    var completedDate: Date
    var clientName: String?
    var category: JobCategory?
    var images: [String]  // All job photos
    var beforeAfterGridImage: String?  // Generated before/after grid
    var beforePhotoIndex: Int?  // Index of selected "before" photo
    var afterPhotoIndex: Int?  // Index of selected "after" photo
    var finalPrice: Double?  // Price from the accepted offer
    var location: String?  // Job location
    var rating: Double?
    var review: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case contractorId
        case jobId
        case title
        case description
        case completedDate
        case clientName
        case category
        case images
        case beforeAfterGridImage
        case beforePhotoIndex
        case afterPhotoIndex
        case finalPrice
        case location
        case rating
        case review
    }
}

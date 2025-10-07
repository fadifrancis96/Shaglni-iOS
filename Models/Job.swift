//
//  Job.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import FirebaseFirestore
import CoreLocation

enum JobStatus: String, Codable {
    case open = "open"
    case inProgress = "in_progress"
    case completed = "completed"
}

enum JobCategory: String, Codable, CaseIterable {
    case plumbing = "Plumbing"
    case electrical = "Electrical"
    case carpentry = "Carpentry"
    case painting = "Painting"
    case cleaning = "Cleaning"
    case landscaping = "Landscaping"
    case hvac = "HVAC"
    case roofing = "Roofing"
    case flooring = "Flooring"
    case masonry = "Masonry"
    case welding = "Welding"
    case automotive = "Automotive"
    case appliance = "Appliance Repair"
    case pest = "Pest Control"
    case moving = "Moving"
    case other = "Other"
    
    var localizedKey: String {
        return "category.\(self.rawValue)"
    }
}

struct Job: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var location: String
    var latitude: Double?
    var longitude: Double?
    var datePosted: Date
    var createdBy: String
    var status: JobStatus
    var category: JobCategory?
    var budget: Double?
    var photoURLs: [String] = []
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case location
        case latitude
        case longitude
        case datePosted
        case createdBy
        case status
        case category
        case budget
        case photoURLs
    }
    
    // Hashable conformance
    static func == (lhs: Job, rhs: Job) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//
//  Job.swift
//  Shaglni
//

import Foundation
import FirebaseFirestore
import CoreLocation

enum JobStatus: String, Codable {
    case open        = "open"
    case inProgress  = "in_progress"
    case completed   = "completed"
}

enum JobCategory: String, Codable, CaseIterable {
    case plumbing   = "Plumbing"
    case electrical = "Electrical"
    case carpentry  = "Carpentry"
    case painting   = "Painting"
    case cleaning   = "Cleaning"
    case landscaping = "Landscaping"
    case hvac       = "HVAC"
    case roofing    = "Roofing"
    case flooring   = "Flooring"
    case masonry    = "Masonry"
    case welding    = "Welding"
    case automotive = "Automotive"
    case appliance  = "Appliance Repair"
    case pest       = "Pest Control"
    case moving     = "Moving"
    case other      = "Other"
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
    var photoURLs: [String]?

    /// Denormalised — set when an offer is accepted. Lets us query "my active jobs"
    /// without a per-job offers subquery.
    var acceptedOfferId: String?
    var acceptedContractorId: String?
    var acceptedPrice: Double?
    var acceptedAt: Date?
    var completedAt: Date?

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, location, latitude, longitude
        case datePosted, createdBy, status, category, budget, photoURLs
        case acceptedOfferId, acceptedContractorId, acceptedPrice, acceptedAt, completedAt
    }

    // Hashable conformance based on id only — used by NavigationStack value-based routing.
    static func == (lhs: Job, rhs: Job) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

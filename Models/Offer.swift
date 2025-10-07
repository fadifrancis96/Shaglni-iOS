//
//  Offer.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import FirebaseFirestore

enum OfferStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case counterOffer = "counter_offer"  // Job poster wants to negotiate
}

struct Offer: Identifiable, Codable {
    @DocumentID var id: String?
    var jobId: String
    var contractorId: String
    var contractorName: String
    var message: String
    var price: Double
    var status: OfferStatus
    var createdAt: Date
    
    // Negotiation fields
    var counterPrice: Double?  // Price suggested by job poster
    var negotiationMessage: String?  // Message explaining the counter offer
    var respondedAt: Date?  // When job poster responded
    
    enum CodingKeys: String, CodingKey {
        case id
        case jobId
        case contractorId
        case contractorName
        case message
        case price
        case status
        case createdAt
        case counterPrice
        case negotiationMessage
        case respondedAt
    }
}

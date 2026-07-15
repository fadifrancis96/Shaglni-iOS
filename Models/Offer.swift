//
//  Offer.swift
//  Shaglni
//

import Foundation
import FirebaseFirestore

enum OfferStatus: String, Codable, Equatable {
    case pending      = "pending"
    case accepted     = "accepted"
    case rejected     = "rejected"
    case counterOffer = "counter_offer"  // Job poster suggested a different price
}

struct Offer: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var jobId: String
    var contractorId: String
    var contractorName: String
    var message: String
    var price: Double
    var status: OfferStatus
    var createdAt: Date

    // Negotiation
    var counterPrice: Double?
    var negotiationMessage: String?
    var respondedAt: Date?
    var contractorAcceptedCounter: Bool?
    var finalPrice: Double?

    /// Effective price the parties are debating right now — counter if proposed,
    /// otherwise the original. The accepted price lives on `finalPrice` when both parties agree.
    var currentPrice: Double { counterPrice ?? price }

    /// Convenience: render the agreed-upon price if accepted, else the current price.
    var displayPrice: Double { finalPrice ?? counterPrice ?? price }

    enum CodingKeys: String, CodingKey {
        case id, jobId, contractorId, contractorName, message, price, status, createdAt
        case counterPrice, negotiationMessage, respondedAt, contractorAcceptedCounter, finalPrice
    }

    static func == (lhs: Offer, rhs: Offer) -> Bool { lhs.id == rhs.id }
}

/// Higher-level, type-safe view of where an offer currently sits in the negotiation flow.
/// Derived from the persisted flat fields so the Firestore wire format doesn't change —
/// pattern-match on this in view code instead of juggling status + booleans manually.
enum NegotiationState: Equatable {
    case pending(askingPrice: Double)
    case countered(askingPrice: Double, counterPrice: Double, message: String?)
    case contractorAcceptedCounter(finalPrice: Double)
    case accepted(finalPrice: Double)
    case rejected
}

extension Offer {
    var negotiationState: NegotiationState {
        switch status {
        case .accepted:
            return .accepted(finalPrice: finalPrice ?? counterPrice ?? price)
        case .rejected:
            return .rejected
        case .counterOffer:
            if contractorAcceptedCounter == true {
                return .contractorAcceptedCounter(finalPrice: finalPrice ?? counterPrice ?? price)
            } else {
                return .countered(askingPrice: price, counterPrice: counterPrice ?? price, message: negotiationMessage)
            }
        case .pending:
            return .pending(askingPrice: price)
        }
    }
}

// Helper view-model structs that pair offers with their jobs.
struct OfferWithJob: Identifiable, Equatable {
    var offer: Offer
    var job: Job
    var id: String? { offer.id }

    static func == (lhs: OfferWithJob, rhs: OfferWithJob) -> Bool { lhs.id == rhs.id }
}

struct JobWithOffer: Identifiable, Equatable {
    var job: Job
    var offer: Offer
    var id: String? { job.id }

    static func == (lhs: JobWithOffer, rhs: JobWithOffer) -> Bool { lhs.id == rhs.id }
}

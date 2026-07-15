//
//  ShaglniTests.swift
//  ShaglniTests
//

import Testing
import Foundation
import FirebaseFirestore
@testable import Shaglni

// MARK: - Offer negotiation state machine

struct NegotiationStateTests {

    private func makeOffer(
        status: OfferStatus,
        price: Double = 100,
        counterPrice: Double? = nil,
        contractorAcceptedCounter: Bool? = nil,
        finalPrice: Double? = nil,
        negotiationMessage: String? = nil
    ) -> Offer {
        Offer(
            jobId: "job1",
            contractorId: "c1",
            contractorName: "Contractor",
            message: "I can do it",
            price: price,
            status: status,
            createdAt: Date(),
            counterPrice: counterPrice,
            negotiationMessage: negotiationMessage,
            respondedAt: nil,
            contractorAcceptedCounter: contractorAcceptedCounter,
            finalPrice: finalPrice
        )
    }

    @Test func pendingOffer() {
        let offer = makeOffer(status: .pending, price: 250)
        #expect(offer.negotiationState == .pending(askingPrice: 250))
    }

    @Test func counteredOffer() {
        let offer = makeOffer(status: .counterOffer, price: 300, counterPrice: 200, negotiationMessage: "Too high")
        #expect(offer.negotiationState == .countered(askingPrice: 300, counterPrice: 200, message: "Too high"))
    }

    @Test func counteredOfferWithoutPriceFallsBackToAsking() {
        let offer = makeOffer(status: .counterOffer, price: 300)
        #expect(offer.negotiationState == .countered(askingPrice: 300, counterPrice: 300, message: nil))
    }

    @Test func contractorAcceptedCounter() {
        let offer = makeOffer(status: .counterOffer, price: 300, counterPrice: 200, contractorAcceptedCounter: true, finalPrice: 200)
        #expect(offer.negotiationState == .contractorAcceptedCounter(finalPrice: 200))
    }

    @Test func acceptedOfferUsesFinalPrice() {
        let offer = makeOffer(status: .accepted, price: 300, counterPrice: 200, finalPrice: 200)
        #expect(offer.negotiationState == .accepted(finalPrice: 200))
    }

    @Test func acceptedOfferFallsBackThroughCounterThenAsking() {
        #expect(makeOffer(status: .accepted, price: 300, counterPrice: 250).negotiationState == .accepted(finalPrice: 250))
        #expect(makeOffer(status: .accepted, price: 300).negotiationState == .accepted(finalPrice: 300))
    }

    @Test func rejectedOffer() {
        #expect(makeOffer(status: .rejected).negotiationState == .rejected)
    }

    @Test func priceFallbackChains() {
        let bare = makeOffer(status: .pending, price: 100)
        #expect(bare.currentPrice == 100)
        #expect(bare.displayPrice == 100)

        let countered = makeOffer(status: .counterOffer, price: 100, counterPrice: 80)
        #expect(countered.currentPrice == 80)
        #expect(countered.displayPrice == 80)

        let settled = makeOffer(status: .accepted, price: 100, counterPrice: 80, finalPrice: 90)
        #expect(settled.currentPrice == 80)
        #expect(settled.displayPrice == 90)
    }
}

// MARK: - ChatThread

struct ChatThreadTests {

    private func makeThread() -> ChatThread {
        ChatThread(
            id: "job1",
            jobId: "job1",
            jobTitle: "Fix the sink",
            jobPosterId: "poster1",
            jobPosterName: "Poster",
            contractorId: "contractor1",
            contractorName: "Contractor",
            lastMessage: "",
            lastMessageAt: Date(),
            lastMessageSenderId: "",
            unreadCounts: ["poster1": 0, "contractor1": 0],
            participantIds: ["poster1", "contractor1"]
        )
    }

    /// Regression test: `participantIds` must be a STORED field that reaches the
    /// Firestore document. When it was a computed property it was silently dropped
    /// from serialization, which broke the thread-list query and the security rules.
    @Test func participantIdsIsSerialized() throws {
        let encoded = try Firestore.Encoder().encode(makeThread())
        #expect(encoded["participantIds"] as? [String] == ["poster1", "contractor1"])
    }

    @Test func otherParticipantResolution() {
        let thread = makeThread()
        #expect(thread.otherParticipantId(for: "poster1") == "contractor1")
        #expect(thread.otherParticipantId(for: "contractor1") == "poster1")
        #expect(thread.otherParticipantName(for: "poster1") == "Contractor")
        #expect(thread.otherParticipantName(for: "contractor1") == "Poster")
    }

    @Test func unreadCountDefaultsToZero() {
        let thread = makeThread()
        #expect(thread.unreadCount(for: "poster1") == 0)
        #expect(thread.unreadCount(for: "unknown-user") == 0)
    }
}

// MARK: - Money

struct MoneyTests {

    @Test func wholeShekelHasNoFraction() {
        let s = Money.string(1234.56)
        #expect(s.contains(Money.currencySymbol))
        #expect(s.contains("1"))
        // Whole-shekel formatter must round away the fraction entirely.
        #expect(!s.contains("56"))
    }

    @Test func preciseKeepsFraction() {
        let s = Money.precise(99.5)
        #expect(s.contains(Money.currencySymbol))
        #expect(s.contains("99"))
        #expect(s.contains("5"))
    }

    @Test func zeroAndSmallValues() {
        #expect(Money.string(0).contains("0"))
        #expect(Money.string(50).contains("50"))
    }
}

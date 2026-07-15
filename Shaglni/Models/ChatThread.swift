//
//  ChatThread.swift
//  Shaglni
//
//  Chat threads are created when an offer is accepted, scoped to a single job.
//  Document id == `jobId` so we can look up the thread directly without a query.
//

import Foundation
import FirebaseFirestore

struct ChatThread: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?

    var jobId: String
    var jobTitle: String

    var jobPosterId: String
    var jobPosterName: String

    var contractorId: String
    var contractorName: String

    var lastMessage: String
    var lastMessageAt: Date
    var lastMessageSenderId: String

    // Per-user unread counts so we can show a badge on either side.
    var unreadCounts: [String: Int]

    // Stored (not computed) so it is serialized to Firestore — the thread-list
    // query (`arrayContains`) and the security rules both depend on this field
    // existing on the document.
    var participantIds: [String]

    func unreadCount(for userId: String) -> Int { unreadCounts[userId] ?? 0 }
    func otherParticipantName(for userId: String) -> String {
        userId == jobPosterId ? contractorName : jobPosterName
    }
    func otherParticipantId(for userId: String) -> String {
        userId == jobPosterId ? contractorId : jobPosterId
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var text: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey { case id, senderId, senderName, text, createdAt }
}

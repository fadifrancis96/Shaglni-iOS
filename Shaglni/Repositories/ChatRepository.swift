//
//  ChatRepository.swift
//  Shaglni
//
//  Chat threads live at `chats/{jobId}` with subcollection `chats/{jobId}/messages`.
//  Thread documents are keyed on `jobId` so we can look them up directly when an
//  offer is accepted, without a separate query.
//

import Foundation
import FirebaseFirestore

@MainActor
final class ChatRepository: ObservableObject {
    static let shared = ChatRepository()

    @Published private(set) var myThreads: [ChatThread] = []

    nonisolated private let db = Firestore.firestore()
    private var threadsListener: ListenerRegistration?

    private init() {}

    // MARK: - Threads

    func observeThreads(for userId: String) {
        stopObservingThreads()
        threadsListener = db.collection("chats")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in
                if let error = error {
                    AppLogger.chat.error("threads listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                self?.myThreads = snap?.decoded(as: ChatThread.self) ?? []
            }
    }

    func stopObservingThreads() {
        threadsListener?.remove()
        threadsListener = nil
        myThreads = []
    }

    /// Create-or-update a thread. Called when an offer is accepted.
    func ensureThread(jobId: String, jobTitle: String, jobPosterId: String, jobPosterName: String, contractorId: String, contractorName: String) async throws {
        let thread = ChatThread(
            id: jobId,
            jobId: jobId,
            jobTitle: jobTitle,
            jobPosterId: jobPosterId,
            jobPosterName: jobPosterName,
            contractorId: contractorId,
            contractorName: contractorName,
            lastMessage: "",
            lastMessageAt: Date(),
            lastMessageSenderId: "",
            unreadCounts: [jobPosterId: 0, contractorId: 0]
        )
        try db.collection("chats").document(jobId).setData(from: thread, merge: true)
    }

    func fetchThread(jobId: String) async throws -> ChatThread? {
        let snap = try await db.collection("chats").document(jobId).getDocument()
        guard snap.exists else { return nil }
        return try snap.data(as: ChatThread.self)
    }

    // MARK: - Messages

    nonisolated func listenMessages(jobId: String, onChange: @escaping @MainActor ([ChatMessage]) -> Void) -> ListenerRegistration {
        db.collection("chats").document(jobId).collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    AppLogger.chat.error("messages listener: \(error.localizedDescription, privacy: .public)")
                    return
                }
                let messages = snapshot?.decoded(as: ChatMessage.self) ?? []
                Task { @MainActor in onChange(messages) }
            }
    }

    func send(text: String, jobId: String, senderId: String, senderName: String, otherParticipantId: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let threadRef = db.collection("chats").document(jobId)
        let messagesRef = threadRef.collection("messages")
        let message = ChatMessage(senderId: senderId, senderName: senderName, text: trimmed, createdAt: Date())
        try messagesRef.addDocument(from: message)

        try await threadRef.updateData([
            "lastMessage": trimmed,
            "lastMessageAt": FieldValue.serverTimestamp(),
            "lastMessageSenderId": senderId,
            "unreadCounts.\(otherParticipantId)": FieldValue.increment(Int64(1))
        ])
    }

    func markRead(jobId: String, userId: String) async throws {
        try await db.collection("chats").document(jobId).updateData([
            "unreadCounts.\(userId)": 0
        ])
    }
}

//
//  ChatView.swift
//  Shaglni
//

import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    let thread: ChatThread

    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var chatRepo: ChatRepository

    @State private var messages: [ChatMessage] = []
    @State private var draft = ""
    @State private var sending = false
    @State private var listener: ListenerRegistration?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { msg in
                            MessageBubble(message: msg, isMine: msg.senderId == myUid)
                                .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField(L10n.Chat.placeholder.string, text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: sending ? "ellipsis" : "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending)
            }
            .padding()
        }
        .navigationTitle(otherName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startListening() }
        .onDisappear { listener?.remove(); listener = nil }
        .task {
            // Mark thread read once we open it.
            guard let uid = myUid, let id = thread.id else { return }
            try? await chatRepo.markRead(jobId: id, userId: uid)
        }
    }

    private var myUid: String? { authViewModel.currentUser?.uid }
    private var otherName: String {
        guard let uid = myUid else { return thread.jobTitle }
        return thread.otherParticipantName(for: uid)
    }

    private func startListening() {
        guard let id = thread.id, listener == nil else { return }
        listener = chatRepo.listenMessages(jobId: id) { msgs in
            self.messages = msgs
        }
    }

    private func send() async {
        guard let uid = myUid,
              let senderName = authViewModel.currentUserData?.displayName,
              let id = thread.id else { return }
        let text = draft
        draft = ""
        sending = true
        do {
            try await chatRepo.send(
                text: text, jobId: id,
                senderId: uid, senderName: senderName,
                otherParticipantId: thread.otherParticipantId(for: uid)
            )
        } catch {
            AppLogger.chat.error("send failed: \(error.localizedDescription, privacy: .public)")
            draft = text  // restore
        }
        sending = false
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(isMine ? Color.accentColor : Color(.systemGray5))
                    .foregroundColor(isMine ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !isMine { Spacer(minLength: 40) }
        }
    }
}

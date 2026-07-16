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
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: DS.Space.s) {
                        ForEach(messages) { msg in
                            MessageBubble(message: msg, isMine: msg.senderId == myUid)
                                .id(msg.id)
                        }
                    }
                    .padding(DS.Space.l)
                }
                .background(Color.bgCanvas)
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            // Input bar
            HStack(spacing: DS.Space.s) {
                TextField(L10n.Chat.placeholder.string, text: $draft, axis: .vertical)
                    .font(.dsBody)
                    .lineLimit(1...5)
                    .focused($inputFocused)
                    .padding(.horizontal, DS.Space.l)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.surfaceAlt)
                    )

                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.onBrand)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.brand))
                        .opacity(canSend ? 1 : 0.4)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, DS.Space.l)
            .padding(.vertical, DS.Space.m)
            .background(Color.surface)
            .overlay(alignment: .top) {
                Divider().overlay(Color.divider)
            }
        }
        .navigationTitle(otherName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .onAppear { startListening() }
        .onDisappear { listener?.remove(); listener = nil }
        .task {
            // Mark thread read once we open it.
            guard let uid = myUid, let id = thread.id else { return }
            try? await chatRepo.markRead(jobId: id, userId: uid)
        }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !sending
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
            if isMine { Spacer(minLength: 48) }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(.dsBody)
                    .foregroundStyle(isMine ? Color.onBrand : Color.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: isMine ? 18 : 6,
                            bottomTrailingRadius: isMine ? 6 : 18,
                            topTrailingRadius: 18,
                            style: .continuous
                        )
                        .fill(isMine ? Color.brand : Color.surface)
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: isMine ? 18 : 6,
                            bottomTrailingRadius: isMine ? 6 : 18,
                            topTrailingRadius: 18,
                            style: .continuous
                        )
                        .strokeBorder(isMine ? Color.clear : Color.divider, lineWidth: 1)
                    )

                Text(message.createdAt, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkFaint)
            }

            if !isMine { Spacer(minLength: 48) }
        }
    }
}

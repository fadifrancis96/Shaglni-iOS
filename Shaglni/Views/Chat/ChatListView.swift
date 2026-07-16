//
//  ChatListView.swift
//  Shaglni
//

import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var chatRepo: ChatRepository

    var body: some View {
        NavigationStack {
            Group {
                if chatRepo.myThreads.isEmpty {
                    ZStack {
                        Color.bgCanvas.ignoresSafeArea()
                        DSEmptyState(
                            systemImage: "bubble.left.and.bubble.right",
                            title: L10n.Empty.noChats.string,
                            message: L10n.Empty.noChatsSubtitle.string
                        )
                    }
                } else {
                    List(chatRepo.myThreads) { thread in
                        NavigationLink(value: thread) { ChatThreadRow(thread: thread) }
                            .listRowBackground(Color.bgCanvas)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.bgCanvas)
                }
            }
            .navigationTitle(L10n.Tab.chat.string)
            .navigationDestination(for: ChatThread.self) { thread in
                ChatView(thread: thread)
            }
        }
    }
}

private struct ChatThreadRow: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let thread: ChatThread

    var body: some View {
        HStack(spacing: DS.Space.m) {
            DSAvatar(name: otherName, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(otherName)
                    .font(.dsHeadline)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)

                DSTag(title: thread.jobTitle, systemImage: "briefcase.fill")

                if !thread.lastMessage.isEmpty {
                    Text(thread.lastMessage)
                        .font(.dsSub)
                        .foregroundStyle(unread > 0 ? Color.ink : Color.inkMuted)
                        .fontWeight(unread > 0 ? .medium : .regular)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(thread.lastMessageAt, style: .time)
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkFaint)

                if unread > 0 {
                    Text("\(unread)")
                        .font(.dsMicro)
                        .foregroundStyle(Color.onBrand)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.brand))
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var otherName: String {
        guard let uid = authViewModel.currentUser?.uid else { return "" }
        return thread.otherParticipantName(for: uid)
    }
    private var unread: Int {
        guard let uid = authViewModel.currentUser?.uid else { return 0 }
        return thread.unreadCount(for: uid)
    }
}

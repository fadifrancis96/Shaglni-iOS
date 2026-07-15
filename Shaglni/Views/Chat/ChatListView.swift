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
                    EmptyStateView(
                        icon: "bubble.left.and.bubble.right",
                        title: L10n.Empty.noChats.string,
                        subtitle: L10n.Empty.noChatsSubtitle.string
                    )
                } else {
                    List(chatRepo.myThreads) { thread in
                        NavigationLink(value: thread) { ChatThreadRow(thread: thread) }
                    }
                    .listStyle(.plain)
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
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "person.fill").foregroundColor(.accentColor))

            VStack(alignment: .leading, spacing: 4) {
                Text(otherName).font(.headline)
                Text(thread.jobTitle).font(.caption).foregroundStyle(.secondary)
                if !thread.lastMessage.isEmpty {
                    Text(thread.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(thread.lastMessageAt, style: .time)
                    .font(.caption).foregroundStyle(.secondary)
                if unread > 0 {
                    Text("\(unread)")
                        .font(.caption2).fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
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

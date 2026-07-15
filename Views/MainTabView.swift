//
//  MainTabView.swift
//  Shaglni
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var chatRepo: ChatRepository

    var body: some View {
        TabView {
            Group {
                if authViewModel.isJobPoster {
                    JobPosterDashboardView()
                } else {
                    ContractorDashboardView()
                }
            }
            .tabItem { Label(L10n.Tab.dashboard.string, systemImage: "house.fill") }

            JobListView()
                .tabItem { Label(L10n.Tab.jobs.string, systemImage: "briefcase.fill") }

            if authViewModel.isJobPoster {
                ContractorListView()
                    .tabItem { Label(L10n.Tab.contractors.string, systemImage: "person.3.fill") }
            }

            if authViewModel.isContractor {
                MyOffersView()
                    .tabItem { Label(L10n.Tab.offers.string, systemImage: "doc.text.fill") }
            }

            ChatListView()
                .tabItem {
                    Label(L10n.Tab.chat.string, systemImage: "bubble.left.and.bubble.right.fill")
                }
                .badge(totalUnread)

            ProfileView()
                .tabItem { Label(L10n.Tab.profile.string, systemImage: "person.fill") }
        }
    }

    private var totalUnread: Int {
        guard let uid = authViewModel.currentUser?.uid else { return 0 }
        return chatRepo.myThreads.reduce(0) { $0 + $1.unreadCount(for: uid) }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(ChatRepository.shared)
}

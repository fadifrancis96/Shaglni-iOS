//
//  ContractorDashboardView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct ContractorDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var jobsRepo: JobsRepository
    @EnvironmentObject var offersRepo: OffersRepository
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.welcome.string)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let userName = authViewModel.currentUserData?.displayName {
                            Text(userName)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Quick Actions
                    VStack(spacing: 16) {
                        NavigationLink(destination: MyActiveJobsView()) {
                            ActionCard(
                                title: L10n.Action.myActiveJobs.string,
                                subtitle: L10n(key: "dashboard.activeJobsSubtitle").string,
                                icon: "hammer.fill",
                                color: .orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: JobListView()) {
                            ActionCard(
                                title: L10n.Action.browseJobs.string,
                                subtitle: L10n(key: "dashboard.browseJobsSubtitle").string,
                                icon: "magnifyingglass.circle.fill",
                                color: .blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: MyPortfolioView()) {
                            ActionCard(
                                title: L10n.Action.myPortfolio.string,
                                subtitle: L10n(key: "dashboard.portfolioSubtitle").string,
                                icon: "photo.stack.fill",
                                color: .purple
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: ManageProfileView()) {
                            ActionCard(
                                title: L10n.Action.manageProfile.string,
                                subtitle: L10n(key: "dashboard.manageProfileSubtitle").string,
                                icon: "person.circle.fill",
                                color: .green
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 16) {
                        StatCard(
                            title: L10n.OfferStatusL.pending.string,
                            value: "\(pendingOffersCount)",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: L10n.OfferStatusL.accepted.string,
                            value: "\(acceptedOffersCount)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Available Jobs
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(L10n.Section.availableJobs.string)
                                .font(.headline)

                            Spacer()

                            NavigationLink(destination: JobListView()) {
                                Text(L10n.Action.viewAll.string)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if jobsRepo.isLoadingOpenJobs {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if availableJobs.isEmpty {
                            EmptyStateView(
                                icon: "briefcase",
                                title: L10n(key: "dashboard.noJobsAvailable").string,
                                subtitle: L10n(key: "dashboard.checkBackLater").string
                            )
                        } else {
                            ForEach(availableJobs.prefix(5)) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    // Recent Offers
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(L10n.Section.myRecentOffers.string)
                                .font(.headline)

                            Spacer()

                            NavigationLink(destination: MyOffersView()) {
                                Text(L10n.Action.viewAll.string)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if myOffers.isEmpty {
                            EmptyStateView(
                                icon: "doc.text",
                                title: L10n.Empty.noOffers.string,
                                subtitle: L10n.Empty.submitOffers.string
                            )
                        } else {
                            ForEach(myOffers.prefix(3)) { offer in
                                OfferCardView(offer: offer)
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle(L10n.Tab.dashboard.string)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var availableJobs: [Job] {
        jobsRepo.openJobs
    }

    private var myOffers: [Offer] {
        offersRepo.myOffers
    }

    private var pendingOffersCount: Int {
        myOffers.filter { $0.status == .pending }.count
    }
    
    private var acceptedOffersCount: Int {
        myOffers.filter { $0.status == .accepted }.count
    }
}

#Preview {
    ContractorDashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
        .environmentObject(OffersRepository.shared)
}

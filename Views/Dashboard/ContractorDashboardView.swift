//
//  ContractorDashboardView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct ContractorDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var jobsRepo: JobsRepository
    @EnvironmentObject var offersRepo: OffersRepository
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("welcome"))
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
                                title: "My Active Jobs",
                                subtitle: "View your in-progress jobs",
                                icon: "hammer.fill",
                                color: .orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: JobListView()) {
                            ActionCard(
                                title: localization.localized("browseJobs"),
                                subtitle: "Find jobs matching your skills",
                                icon: "magnifyingglass.circle.fill",
                                color: .blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: MyPortfolioView()) {
                            ActionCard(
                                title: "My Portfolio",
                                subtitle: "Manage your completed jobs",
                                icon: "photo.stack.fill",
                                color: .purple
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: ManageProfileView()) {
                            ActionCard(
                                title: localization.localized("manageProfile"),
                                subtitle: "Update your profile and portfolio",
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
                            title: localization.localized("pending"),
                            value: "\(pendingOffersCount)",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: localization.localized("accepted"),
                            value: "\(acceptedOffersCount)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Available Jobs
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Available Jobs")
                                .font(.headline)
                            
                            Spacer()
                            
                            NavigationLink(destination: JobListView()) {
                                Text("View All")
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
                                title: "No jobs available",
                                subtitle: "Check back later for new opportunities"
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
                            Text("My Recent Offers")
                                .font(.headline)
                            
                            Spacer()
                            
                            NavigationLink(destination: MyOffersView()) {
                                Text("View All")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if myOffers.isEmpty {
                            EmptyStateView(
                                icon: "doc.text",
                                title: "No offers yet",
                                subtitle: "Submit offers to jobs you're interested in"
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
            .navigationTitle(localization.localized("dashboard"))
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

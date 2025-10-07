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
    @State private var availableJobs: [Job] = []
    @State private var myOffers: [Offer] = []
    @State private var isLoading = true
    
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
                        NavigationLink(destination: JobListView()) {
                            ActionCard(
                                title: localization.localized("browseJobs"),
                                subtitle: "Find jobs matching your skills",
                                icon: "magnifyingglass.circle.fill",
                                color: .blue
                            )
                        }
                        
                        NavigationLink(destination: ManageProfileView()) {
                            ActionCard(
                                title: localization.localized("manageProfile"),
                                subtitle: "Update your profile and portfolio",
                                icon: "person.circle.fill",
                                color: .green
                            )
                        }
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
                        
                        if isLoading {
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
            .onAppear(perform: loadData)
        }
    }
    
    private var pendingOffersCount: Int {
        myOffers.filter { $0.status == .pending }.count
    }
    
    private var acceptedOffersCount: Int {
        myOffers.filter { $0.status == .accepted }.count
    }
    
    private func loadData() {
        guard let userId = authViewModel.currentUser?.uid else { return }
        
        // Load available jobs
        FirestoreService.shared.fetchJobs(status: .open) { result in
            isLoading = false
            switch result {
            case .success(let jobs):
                availableJobs = jobs
            case .failure(let error):
                print("Error loading jobs: \(error.localizedDescription)")
            }
        }
        
        // Load my offers
        FirestoreService.shared.fetchOffersByContractor(contractorId: userId) { result in
            switch result {
            case .success(let offers):
                myOffers = offers
            case .failure(let error):
                print("Error loading offers: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContractorDashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}

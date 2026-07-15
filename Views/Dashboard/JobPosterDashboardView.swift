//
//  JobPosterDashboardView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct JobPosterDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var jobs: [Job] = []
    @State private var offersWithJobs: [OfferWithJob] = []
    @State private var isLoading = true
    @State private var showPostJob = false
    
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
                    
                    // Action Cards
                    VStack(spacing: 16) {
                        ActionCard(
                            title: localization.localized("postJob"),
                            subtitle: "Post a new job and receive offers",
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            showPostJob = true
                        }
                        
                        NavigationLink(destination: ContractorListView()) {
                            ActionCard(
                                title: localization.localized("findContractor"),
                                subtitle: "Browse contractors by skills",
                                icon: "magnifyingglass.circle.fill",
                                color: .green
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: ReceivedOffersView()) {
                            ActionCard(
                                title: "Received Offers",
                                subtitle: "View offers from contractors",
                                icon: "envelope.circle.fill",
                                color: .purple
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 16) {
                        StatCard(
                            title: localization.localized("open"),
                            value: "\(openJobsCount)",
                            icon: "doc.text.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: localization.localized("inProgress"),
                            value: "\(inProgressJobsCount)",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: localization.localized("completed"),
                            value: "\(completedJobsCount)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Offers Stats
                    if pendingOffersCount > 0 {
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Pending Offers",
                                value: "\(pendingOffersCount)",
                                icon: "envelope.fill",
                                color: .purple
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Recent Jobs
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Jobs")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if jobs.isEmpty {
                            EmptyStateView(
                                icon: "briefcase",
                                title: "No jobs yet",
                                subtitle: "Post your first job to get started"
                            )
                        } else {
                            ForEach(jobs.prefix(5)) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle(localization.localized("dashboard"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPostJob) {
                JobFormView()
            }
            .onAppear {
                loadJobs()
                loadOffers()
            }
        }
    }
    
    private var openJobsCount: Int {
        jobs.filter { $0.status == .open }.count
    }
    
    private var inProgressJobsCount: Int {
        jobs.filter { $0.status == .inProgress }.count
    }
    
    private var completedJobsCount: Int {
        jobs.filter { $0.status == .completed }.count
    }
    
    private var pendingOffersCount: Int {
        offersWithJobs.filter { $0.offer.status == .pending }.count
    }
    
    private func loadJobs() {
        guard let userId = authViewModel.currentUser?.uid else { return }
        
        FirestoreService.shared.fetchJobsByUser(userId: userId) { result in
            isLoading = false
            switch result {
            case .success(let fetchedJobs):
                jobs = fetchedJobs
            case .failure(let error):
                print("Error loading jobs: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadOffers() {
        guard let userId = authViewModel.currentUser?.uid else { return }
        
        FirestoreService.shared.fetchOffersForJobPoster(userId: userId) { result in
            switch result {
            case .success(let fetchedOffers):
                offersWithJobs = fetchedOffers
            case .failure(let error):
                print("Error loading offers: \(error.localizedDescription)")
            }
        }
    }
}

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Group {
            if action != nil {
                Button(action: action!) {
                    cardContent
                }
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle()) // Makes entire area tappable
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    JobPosterDashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}

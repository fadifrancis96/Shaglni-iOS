//
//  JobPosterDashboardView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct JobPosterDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var jobsRepo: JobsRepository
    @State private var offersWithJobs: [OfferWithJob] = []
    @State private var isLoading = true
    @State private var showPostJob = false
    @State private var errorMessage: String?
    
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
                    
                    // Action Cards
                    VStack(spacing: 16) {
                        ActionCard(
                            title: L10n.Action.postJob.string,
                            subtitle: L10n(key: "dashboard.postJobSubtitle").string,
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            showPostJob = true
                        }
                        
                        NavigationLink(destination: ContractorListView()) {
                            ActionCard(
                                title: L10n.Action.findContractor.string,
                                subtitle: L10n(key: "dashboard.findContractorSubtitle").string,
                                icon: "magnifyingglass.circle.fill",
                                color: .green
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: ReceivedOffersView()) {
                            ActionCard(
                                title: L10n.Action.receivedOffers.string,
                                subtitle: L10n(key: "dashboard.receivedOffersSubtitle").string,
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
                            title: L10n.JobStatus.open.string,
                            value: "\(openJobsCount)",
                            icon: "doc.text.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: L10n.JobStatus.inProgress.string,
                            value: "\(inProgressJobsCount)",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: L10n.JobStatus.completed.string,
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
                                title: L10n(key: "dashboard.pendingOffers").string,
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
                        Text(L10n.Section.recentJobs.string)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if jobsRepo.myPostedJobs.isEmpty {
                            EmptyStateView(
                                icon: "briefcase",
                                title: L10n.Empty.noJobs.string,
                                subtitle: L10n.Empty.postFirstJob.string
                            )
                        } else {
                            ForEach(jobsRepo.myPostedJobs.prefix(5)) { job in
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
            .navigationTitle(L10n.Tab.dashboard.string)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPostJob) {
                JobFormView()
            }
            .task {
                await loadOffers()
            }
            .refreshable {
                await loadOffers()
            }
            .onChange(of: jobsRepo.myPostedJobs) { _, _ in
                Task { await loadOffers() }
            }
            .alert(L10n.Common.error.string, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button(L10n(key: "common.ok").string, role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var openJobsCount: Int {
        jobsRepo.myPostedJobs.filter { $0.status == .open }.count
    }

    private var inProgressJobsCount: Int {
        jobsRepo.myPostedJobs.filter { $0.status == .inProgress }.count
    }

    private var completedJobsCount: Int {
        jobsRepo.myPostedJobs.filter { $0.status == .completed }.count
    }

    private var pendingOffersCount: Int {
        offersWithJobs.filter { $0.offer.status == .pending }.count
    }

    private func loadOffers() async {
        guard let userId = authViewModel.currentUser?.uid else {
            isLoading = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            offersWithJobs = try await OffersRepository.shared.fetchOffersForJobPoster(userId, jobs: jobsRepo.myPostedJobs)
        } catch {
            errorMessage = AppError(error).errorDescription
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
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
}

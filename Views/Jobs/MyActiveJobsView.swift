//
//  MyActiveJobsView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI

struct MyActiveJobsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var activeJobs: [JobWithOffer] = []
    @State private var completedJobs: [JobWithOffer] = []
    @State private var isLoading = true
    @State private var selectedJob: JobWithOffer?
    @State private var showJobDetail = false
    @State private var newlyCompletedJob: JobWithOffer?
    @State private var showCompletionPreview = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading && activeJobs.isEmpty && completedJobs.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 400)
                            .padding()
                    } else if !isLoading && activeJobs.isEmpty && completedJobs.isEmpty {
                        EmptyStateView(
                            icon: "briefcase.fill",
                            title: "No Active Jobs",
                            subtitle: "You don't have any active jobs right now. Your in-progress jobs will appear here."
                        )
                    } else {
                        // Active Jobs Section
                        if !activeJobs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("In Progress")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(activeJobs) { jobWithOffer in
                                    ActiveJobCard(jobWithOffer: jobWithOffer)
                                        .onTapGesture {
                                            selectedJob = jobWithOffer
                                            showJobDetail = true
                                        }
                                }
                            }
                        }
                        
                        // Completed Jobs Section
                        if !completedJobs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Completed - Add to Profile")
                                    .font(.headline)
                                    .padding(.horizontal)
                                    .padding(.top)
                                
                                ForEach(completedJobs) { jobWithOffer in
                                    CompletedJobCard(jobWithOffer: jobWithOffer)
                                        .onTapGesture {
                                            // Open to job detail view so contractor can view the job first
                                            selectedJob = jobWithOffer
                                            showJobDetail = true
                                        }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("My Active Jobs")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                loadActiveJobs()
            }
            .onAppear {
                loadActiveJobs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("JobCompleted"))) { _ in
                // Refresh when a job is completed
                loadActiveJobs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OfferStatusUpdated"))) { _ in
                // Refresh when offer status changes
                loadActiveJobs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CompletedJobAdded"))) { _ in
                // Refresh when a job is added to portfolio
                loadActiveJobs()
            }
            .sheet(item: $selectedJob) { jobWithOffer in
                NavigationStack {
                    ActiveJobDetailView(jobWithOffer: jobWithOffer)
                        .onDisappear {
                            // Refresh when returning from job detail
                            loadActiveJobs()
                        }
                }
            }
            .sheet(isPresented: $showCompletionPreview) {
                if let completedJob = newlyCompletedJob {
                    JobCompletionPreviewView(jobWithOffer: completedJob)
                }
            }
        }
    }
    
    private func loadActiveJobs() {
        guard let contractorId = authViewModel.currentUser?.uid else {
            print("❌ No contractor ID available")
            return
        }
        
        print("🔍 Loading active jobs for contractor: \(contractorId)")
        isLoading = true
        
        // Fetch all jobs where contractor has an accepted offer
        FirestoreService.shared.fetchJobsWithAcceptedOffer(contractorId: contractorId) { [self] result in
            switch result {
            case .success(let jobs):
                print("📊 Fetched \(jobs.count) jobs total")
                
                // Separate active and completed jobs
                activeJobs = jobs.filter { $0.job.status == .inProgress || $0.job.status == .open }
                let allCompletedJobs = jobs.filter { $0.job.status == .completed }
                
                // Fetch portfolio jobs to filter out already added ones
                FirestoreService.shared.fetchCompletedJobs(contractorId: contractorId) { portfolioResult in
                    isLoading = false
                    switch portfolioResult {
                    case .success(let portfolioJobs):
                        // Get set of job IDs that are already in portfolio
                        let portfolioJobIds = Set(portfolioJobs.compactMap { $0.jobId })
                        
                        // Filter out completed jobs that are already in portfolio
                        completedJobs = allCompletedJobs.filter { jobWithOffer in
                            guard let jobId = jobWithOffer.job.id else { return true }
                            return !portfolioJobIds.contains(jobId)
                        }
                        
                        print("✅ Active jobs: \(activeJobs.count), Completed (not in portfolio): \(completedJobs.count)")
                        
                        // Check if there's a newly completed job to show preview
                        if let firstCompleted = completedJobs.first,
                           newlyCompletedJob == nil {
                            // Small delay to ensure UI is ready
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                newlyCompletedJob = firstCompleted
                                showCompletionPreview = true
                            }
                        }
                    case .failure(let error):
                        // If we can't fetch portfolio, show all completed jobs
                        completedJobs = allCompletedJobs
                        isLoading = false
                        print("Error loading portfolio: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                isLoading = false
                print("Error loading active jobs: \(error.localizedDescription)")
            }
        }
    }
}

struct CompletedJobCard: View {
    let jobWithOffer: JobWithOffer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(jobWithOffer.job.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let category = jobWithOffer.job.category {
                        Text(category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
            
            Text(jobWithOffer.job.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                let finalPrice = jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
                Text("Final Price: ₪\(String(format: "%.0f", finalPrice))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            HStack {
                Image(systemName: "eye.fill")
                    .font(.caption)
                Text("Tap to view job details and add to profile")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.05), Color.blue.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

struct ActiveJobCard: View {
    let jobWithOffer: JobWithOffer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(jobWithOffer.job.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let category = jobWithOffer.job.category {
                        Text(category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                StatusBadge(status: jobWithOffer.job.status)
            }
            
            Text(jobWithOffer.job.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(jobWithOffer.job.location, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if jobWithOffer.job.status == .inProgress {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text("In Progress")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accepted Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    let finalPrice = jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
                    Text("₪\(String(format: "%.0f", finalPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    MyActiveJobsView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}


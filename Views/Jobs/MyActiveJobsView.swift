//
//  MyActiveJobsView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI

struct MyActiveJobsView: View {
    @EnvironmentObject var jobsRepo: JobsRepository
    @EnvironmentObject var offersRepo: OffersRepository
    @EnvironmentObject var portfolioRepo: PortfolioRepository
    @State private var selectedJob: JobWithOffer?
    @State private var newlyCompletedJob: JobWithOffer?
    @State private var showCompletionPreview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if activeJobs.isEmpty && completedJobs.isEmpty {
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
            .onAppear {
                maybeShowCompletionPreview()
            }
            .onChange(of: completedJobs) { _, _ in
                maybeShowCompletionPreview()
            }
            .sheet(item: $selectedJob) { jobWithOffer in
                NavigationStack {
                    ActiveJobDetailView(jobWithOffer: jobWithOffer)
                }
            }
            .sheet(isPresented: $showCompletionPreview) {
                if let completedJob = newlyCompletedJob {
                    JobCompletionPreviewView(jobWithOffer: completedJob)
                }
            }
        }
    }

    /// Live pairing of the contractor's won jobs with the offer that won them.
    private var jobsWithOffers: [JobWithOffer] {
        jobsRepo.myActiveJobs.compactMap { job in
            let offer = offersRepo.myOffers.first(where: { $0.id != nil && $0.id == job.acceptedOfferId })
                ?? offersRepo.myOffers.first(where: { $0.jobId == job.id })
            guard let offer else { return nil }
            return JobWithOffer(job: job, offer: offer)
        }
    }

    private var activeJobs: [JobWithOffer] {
        jobsWithOffers.filter { $0.job.status == .inProgress || $0.job.status == .open }
    }

    /// Completed jobs the contractor hasn't added to their portfolio yet.
    private var completedJobs: [JobWithOffer] {
        let portfolioJobIds = Set(portfolioRepo.myPortfolio.compactMap { $0.jobId })
        return jobsWithOffers.filter { jobWithOffer in
            guard jobWithOffer.job.status == .completed else { return false }
            guard let jobId = jobWithOffer.job.id else { return true }
            return !portfolioJobIds.contains(jobId)
        }
    }

    private func maybeShowCompletionPreview() {
        guard newlyCompletedJob == nil, let firstCompleted = completedJobs.first else { return }
        // Small delay to ensure UI is ready before presenting the sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard newlyCompletedJob == nil else { return }
            newlyCompletedJob = firstCompleted
            showCompletionPreview = true
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
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
        .environmentObject(OffersRepository.shared)
        .environmentObject(PortfolioRepository.shared)
}


//
//  ActiveJobDetailView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI
import MapKit
import Combine

struct ActiveJobDetailView: View {
    let jobWithOffer: JobWithOffer
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var jobStatus: JobStatus
    @State private var showCompletionPreview = false
    
    init(jobWithOffer: JobWithOffer) {
        self.jobWithOffer = jobWithOffer
        _jobStatus = State(initialValue: jobWithOffer.job.status)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(jobWithOffer.job.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        StatusBadge(status: jobStatus)
                    }
                    
                    if let category = jobWithOffer.job.category {
                        Label(category.rawValue, systemImage: "tag.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Divider()
                
                // Job Info Card
                VStack(alignment: .leading, spacing: 16) {
                    // Accepted Offer Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Your Offer Was Accepted")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        let finalPrice = jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
                        HStack {
                            Text("Accepted Price:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("₪\(String(format: "%.0f", finalPrice))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("description"))
                            .font(.headline)
                        
                        Text(jobWithOffer.job.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("location"))
                            .font(.headline)
                        
                        Label(jobWithOffer.job.location, systemImage: "mappin.circle.fill")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Map Preview
                        if let coordinate = jobWithOffer.job.coordinate {
                            Map(position: .constant(.region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            )))) {
                                Marker(jobWithOffer.job.title, coordinate: coordinate)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Status Message
                    if jobStatus == .inProgress {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                Text("Job In Progress")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            
                            Text("The job poster has marked this job as in progress. Complete the work and wait for them to mark it as done.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    } else if jobStatus == .completed {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Job Completed!")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    
                                    Text("The job poster has marked this job as completed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add to Your Portfolio")
                                    .font(.headline)
                                
                                Text("Showcase this completed work on your profile by adding photos and creating a before/after comparison. This will help potential clients see your quality of work.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                showCompletionPreview = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Add to Profile")
                                            .fontWeight(.semibold)
                                            .font(.headline)
                                        Text("Upload photos & create before/after")
                                            .font(.caption)
                                            .opacity(0.9)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            
                            // Optional: Show if already in portfolio
                            checkIfAlreadyInPortfolio { isInPortfolio in
                                if isInPortfolio {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("This job is already in your portfolio")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.green.opacity(0.05), Color.blue.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshJobStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("JobCompleted"))) { notification in
            if let completedJobId = notification.object as? String,
               completedJobId == jobWithOffer.job.id {
                refreshJobStatus()
                // Don't auto-show preview - let contractor view the job first and decide
            }
        }
        .sheet(isPresented: $showCompletionPreview) {
            JobCompletionPreviewView(jobWithOffer: jobWithOffer)
        }
    }
    
    private func refreshJobStatus() {
        guard let jobId = jobWithOffer.job.id else { return }
        
        FirestoreService.shared.fetchJob(jobId: jobId) { result in
            switch result {
            case .success(let updatedJob):
                jobStatus = updatedJob.status
                // Don't auto-show preview - let contractor decide when to add
            case .failure(let error):
                print("Error refreshing job status: \(error.localizedDescription)")
            }
        }
    }
    
    @ViewBuilder
    private func checkIfAlreadyInPortfolio(@ViewBuilder content: @escaping (Bool) -> some View) -> some View {
        Group {
            if let jobId = jobWithOffer.job.id,
               let contractorId = authViewModel.currentUser?.uid {
                CheckPortfolioView(jobId: jobId, contractorId: contractorId) { isInPortfolio in
                    content(isInPortfolio)
                }
            } else {
                content(false)
            }
        }
    }
}

// Helper view to check if job is in portfolio
struct CheckPortfolioView<Content: View>: View {
    let jobId: String
    let contractorId: String
    let content: (Bool) -> Content
    @State private var isInPortfolio = false
    @State private var hasChecked = false
    
    var body: some View {
        Group {
            if hasChecked {
                content(isInPortfolio)
            } else {
                EmptyView()
            }
        }
        .onAppear {
            checkPortfolio()
        }
    }
    
    private func checkPortfolio() {
        FirestoreService.shared.fetchCompletedJobs(contractorId: contractorId) { result in
            switch result {
            case .success(let jobs):
                isInPortfolio = jobs.contains(where: { $0.jobId == jobId })
                hasChecked = true
            case .failure:
                hasChecked = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ActiveJobDetailView(jobWithOffer: JobWithOffer(
            job: Job(
                id: "1",
                title: "Kitchen Plumbing",
                description: "Fix leaking pipes",
                location: "Riyadh",
                datePosted: Date(),
                createdBy: "user1",
                status: .inProgress,
                category: .plumbing
            ),
            offer: Offer(
                id: "1",
                jobId: "1",
                contractorId: "contractor1",
                contractorName: "Ahmed",
                message: "I can do this",
                price: 500,
                status: .accepted,
                createdAt: Date()
            )
        ))
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
    }
}


//
//  ActiveJobDetailView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI
import MapKit

struct ActiveJobDetailView: View {
    let jobWithOffer: JobWithOffer
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var jobsRepo: JobsRepository
    @EnvironmentObject var portfolioRepo: PortfolioRepository
    @State private var showCompletionPreview = false

    /// Live status from the repository's snapshot listener, falling back to the
    /// value the view was constructed with.
    private var jobStatus: JobStatus {
        jobsRepo.myActiveJobs.first(where: { $0.id == jobWithOffer.job.id })?.status ?? jobWithOffer.job.status
    }

    private var isAlreadyInPortfolio: Bool {
        guard let jobId = jobWithOffer.job.id else { return false }
        return portfolioRepo.myPortfolio.contains(where: { $0.jobId == jobId })
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
                            if isAlreadyInPortfolio {
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
        .sheet(isPresented: $showCompletionPreview) {
            JobCompletionPreviewView(jobWithOffer: jobWithOffer)
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
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
        .environmentObject(PortfolioRepository.shared)
    }
}


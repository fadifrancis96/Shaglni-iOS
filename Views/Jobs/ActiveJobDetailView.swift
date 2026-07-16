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
                        Label(category.localized, systemImage: "tag.fill")
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
                            Text(L10n(key: "activeJobs.offerAcceptedTitle").string)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        let finalPrice = jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
                        HStack {
                            Text(L10n(key: "job.acceptedPrice").string + ":")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(Money.string(finalPrice))
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
                        Text(L10n.Field.description.string)
                            .font(.headline)
                        
                        Text(jobWithOffer.job.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Field.location.string)
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
                                Text(L10n(key: "jobDetail.jobInProgress").string)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }

                            Text(L10n(key: "activeJobs.inProgressHint").string)
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
                                    Text(L10n(key: "activeJobs.jobCompletedTitle").string)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)

                                    Text(L10n(key: "activeJobs.completedByPoster").string)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n(key: "activeJobs.addToPortfolio").string)
                                    .font(.headline)

                                Text(L10n(key: "activeJobs.addToPortfolioHint").string)
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
                                        Text(L10n(key: "activeJobs.addToProfile").string)
                                            .fontWeight(.semibold)
                                            .font(.headline)
                                        Text(L10n(key: "activeJobs.uploadPhotosSubtitle").string)
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
                                    Text(L10n(key: "activeJobs.alreadyInPortfolio").string)
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
        .navigationTitle(L10n(key: "job.details").string)
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


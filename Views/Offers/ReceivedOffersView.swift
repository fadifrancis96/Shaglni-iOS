//
//  ReceivedOffersView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct ReceivedOffersView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var jobsRepo: JobsRepository
    @State private var offersWithJobs: [OfferWithJob] = []
    @State private var isLoading = true
    @State private var selectedFilter: OfferStatus?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedFilter == nil
                        ) {
                            selectedFilter = nil
                        }
                        
                        FilterChip(
                            title: localization.localized("pending"),
                            isSelected: selectedFilter == .pending
                        ) {
                            selectedFilter = .pending
                        }
                        
                        FilterChip(
                            title: localization.localized("accepted"),
                            isSelected: selectedFilter == .accepted
                        ) {
                            selectedFilter = .accepted
                        }
                        
                        FilterChip(
                            title: localization.localized("rejected"),
                            isSelected: selectedFilter == .rejected
                        ) {
                            selectedFilter = .rejected
                        }
                        
                        FilterChip(
                            title: "Counter Offer",
                            isSelected: selectedFilter == .counterOffer
                        ) {
                            selectedFilter = .counterOffer
                        }
                    }
                    .padding()
                }
                
                // Offers List
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredOffers.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No offers received",
                        subtitle: "Offers from contractors will appear here when they submit offers to your jobs"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredOffers) { offerWithJob in
                                NavigationLink(
                                    destination: OfferDetailView(
                                        offer: offerWithJob.offer,
                                        jobId: offerWithJob.job.id ?? offerWithJob.offer.jobId
                                    )
                                ) {
                                    ReceivedOfferCardView(offerWithJob: offerWithJob)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Received Offers")
            .navigationBarTitleDisplayMode(.inline)
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
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var filteredOffers: [OfferWithJob] {
        if let filter = selectedFilter {
            return offersWithJobs.filter { $0.offer.status == filter }
        }
        return offersWithJobs
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

struct ReceivedOfferCardView: View {
    let offerWithJob: OfferWithJob
    @EnvironmentObject var localization: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Job Title Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offerWithJob.job.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("From: \(offerWithJob.offer.contractorName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                OfferStatusBadge(status: offerWithJob.offer.status)
            }
            
            // Counter Offer Alert
            if offerWithJob.offer.status == .counterOffer && offerWithJob.offer.contractorAcceptedCounter == true {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Contractor accepted your counter offer")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            } else if offerWithJob.offer.status == .counterOffer {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("Waiting for contractor response")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Message
            Text(offerWithJob.offer.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Price and Date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("₪\(Int(offerWithJob.offer.price))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        if let counterPrice = offerWithJob.offer.counterPrice {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("₪\(Int(counterPrice))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if offerWithJob.offer.counterPrice != nil {
                        Text("Your counter offer")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(offerWithJob.offer.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let respondedAt = offerWithJob.offer.respondedAt {
                        Text("Responded \(respondedAt, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            offerWithJob.offer.status == .counterOffer && offerWithJob.offer.contractorAcceptedCounter == true
                ? Color.green.opacity(0.05)
                : offerWithJob.offer.status == .counterOffer
                    ? Color.orange.opacity(0.05)
                    : Color(.systemGray6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    offerWithJob.offer.status == .counterOffer && offerWithJob.offer.contractorAcceptedCounter == true
                        ? Color.green.opacity(0.3)
                        : offerWithJob.offer.status == .counterOffer
                            ? Color.orange.opacity(0.3)
                            : Color.clear,
                    lineWidth: 1
                )
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ReceivedOffersView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
}






//
//  ReceivedOffersView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct ReceivedOffersView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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
                            title: L10n.Filter.all.string,
                            isSelected: selectedFilter == nil
                        ) {
                            selectedFilter = nil
                        }

                        FilterChip(
                            title: OfferStatus.pending.localized,
                            isSelected: selectedFilter == .pending
                        ) {
                            selectedFilter = .pending
                        }

                        FilterChip(
                            title: OfferStatus.accepted.localized,
                            isSelected: selectedFilter == .accepted
                        ) {
                            selectedFilter = .accepted
                        }

                        FilterChip(
                            title: OfferStatus.rejected.localized,
                            isSelected: selectedFilter == .rejected
                        ) {
                            selectedFilter = .rejected
                        }

                        FilterChip(
                            title: OfferStatus.counterOffer.localized,
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
                        title: L10n(key: "receivedOffers.empty.title").string,
                        subtitle: L10n(key: "receivedOffers.empty.subtitle").string
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
            .navigationTitle(L10n.Action.receivedOffers.string)
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
                Button(L10n(key: "common.ok").string, role: .cancel) {}
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Job Title Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(offerWithJob.job.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(L10n(key: "receivedOffers.from").format(offerWithJob.offer.contractorName))
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
                    Text(L10n(key: "receivedOffers.contractorAcceptedCounter").string)
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
                    Text(L10n(key: "receivedOffers.waitingForContractor").string)
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
                        Text(Money.string(offerWithJob.offer.price))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        if let counterPrice = offerWithJob.offer.counterPrice {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(Money.string(counterPrice))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if offerWithJob.offer.counterPrice != nil {
                        Text(L10n(key: "receivedOffers.yourCounterOffer").string)
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
                        Text("\(L10n(key: "offerCard.responded").string) \(respondedAt, style: .relative)")
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






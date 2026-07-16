//
//  MyOffersView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct MyOffersView: View {
    @EnvironmentObject var offersRepo: OffersRepository
    @State private var selectedFilter: OfferStatus?
    
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
                if filteredOffers.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "doc.text",
                        title: L10n.Empty.noOffers.string,
                        subtitle: L10n.Empty.submitOffers.string
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredOffers) { offer in
                                NavigationLink(destination: OfferDetailView(offer: offer, jobId: offer.jobId)) {
                                    OfferCardView(offer: offer)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle(L10n.Action.myOffers.string)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var filteredOffers: [Offer] {
        if let filter = selectedFilter {
            return offersRepo.myOffers.filter { $0.status == filter }
        }
        return offersRepo.myOffers
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

#Preview {
    MyOffersView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(OffersRepository.shared)
}

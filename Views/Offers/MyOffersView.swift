//
//  MyOffersView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct MyOffersView: View {
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var offersRepo: OffersRepository
    @State private var selectedFilter: OfferStatus?
    
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
                if filteredOffers.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "doc.text",
                        title: "No offers",
                        subtitle: "Submit offers to jobs you're interested in"
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
            .navigationTitle(localization.localized("myOffers"))
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

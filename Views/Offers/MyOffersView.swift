//
//  MyOffersView.swift
//  Shaglni
//
//  Contractor's submitted offers: status filter chips over a list of
//  canonical offer cards.
//

import SwiftUI

struct MyOffersView: View {
    @EnvironmentObject var offersRepo: OffersRepository
    @EnvironmentObject var localization: LocalizationManager
    @State private var selectedFilter: OfferStatus?

    private let statusFilters: [OfferStatus] = [.pending, .accepted, .rejected, .counterOffer]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterBar

                    if filteredOffers.isEmpty {
                        Spacer()
                        DSEmptyState(
                            systemImage: "tag",
                            title: L10n.Empty.noOffers.string,
                            message: L10n.Empty.submitOffers.string
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DS.Space.m) {
                                ForEach(filteredOffers) { offer in
                                    NavigationLink(destination: OfferDetailView(offer: offer, jobId: offer.jobId)) {
                                        OfferCardView(offer: offer)
                                    }
                                    .buttonStyle(DSPressableStyle())
                                }
                            }
                            .padding(.horizontal, DS.Space.screen)
                            .padding(.top, DS.Space.xs)
                            .padding(.bottom, DS.Space.xxl)
                        }
                    }
                }
            }
            .navigationTitle(L10n.Action.myOffers.string)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Filter chips

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.s) {
                DSChip(
                    title: L10n.Filter.all.string,
                    isSelected: selectedFilter == nil
                ) {
                    selectedFilter = nil
                }

                ForEach(statusFilters, id: \.rawValue) { status in
                    DSChip(
                        title: status.localized,
                        isSelected: selectedFilter == status
                    ) {
                        selectedFilter = status
                    }
                }
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.vertical, DS.Space.m)
        }
    }

    private var filteredOffers: [Offer] {
        if let filter = selectedFilter {
            return offersRepo.myOffers.filter { $0.status == filter }
        }
        return offersRepo.myOffers
    }
}

#Preview {
    MyOffersView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(OffersRepository.shared)
}

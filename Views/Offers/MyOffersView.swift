//
//  MyOffersView.swift
//  Shaglni
//
//  Contractor's submitted offers: status filter chips over a list of
//  canonical offer cards.
//

import SwiftUI

struct MyOffersView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var offers: [Offer] = []
    @State private var isLoading = true
    @State private var selectedFilter: OfferStatus?

    private let statusFilters: [OfferStatus] = [.pending, .accepted, .rejected, .counterOffer]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterBar

                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(Color.brand)
                        Spacer()
                    } else if filteredOffers.isEmpty {
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
            .onAppear(perform: loadOffers)
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
            return offers.filter { $0.status == filter }
        }
        return offers
    }

    private func loadOffers() {
        guard let userId = authViewModel.currentUser?.uid else { return }

        FirestoreService.shared.fetchOffersByContractor(contractorId: userId) { result in
            isLoading = false
            switch result {
            case .success(let fetchedOffers):
                offers = fetchedOffers
            case .failure(let error):
                print("Error loading offers: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    MyOffersView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}

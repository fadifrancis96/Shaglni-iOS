//
//  ReceivedOffersView.swift
//  Shaglni
//
//  Job poster's inbox of contractor offers: status filter chips over
//  cards pairing each offer with its job.
//

import SwiftUI

struct ReceivedOffersView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var offersWithJobs: [OfferWithJob] = []
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
                            systemImage: "tray",
                            title: "No offers received",
                            message: "Offers from contractors will appear here when they submit offers to your jobs"
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DS.Space.m) {
                                ForEach(filteredOffers) { offerWithJob in
                                    NavigationLink(
                                        destination: OfferDetailView(
                                            offer: offerWithJob.offer,
                                            jobId: offerWithJob.job.id ?? offerWithJob.offer.jobId
                                        )
                                    ) {
                                        ReceivedOfferCardView(offerWithJob: offerWithJob)
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
            .navigationTitle(L10n.Action.receivedOffers.string)
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

    private var filteredOffers: [OfferWithJob] {
        if let filter = selectedFilter {
            return offersWithJobs.filter { $0.offer.status == filter }
        }
        return offersWithJobs
    }

    private func loadOffers() {
        guard let userId = authViewModel.currentUser?.uid else { return }

        FirestoreService.shared.fetchOffersForJobPoster(userId: userId) { result in
            isLoading = false
            switch result {
            case .success(let fetchedOffers):
                offersWithJobs = fetchedOffers
            case .failure(let error):
                print("Error loading offers: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Card

/// Offer row for the job poster: job title, contractor identity, negotiation
/// state notice, message preview and the price transition.
private struct ReceivedOfferCardView: View {
    let offerWithJob: OfferWithJob

    private var offer: Offer { offerWithJob.offer }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(spacing: DS.Space.m) {
                DSAvatar(name: offer.contractorName, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(offerWithJob.job.title)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    Text(offer.contractorName)
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkMuted)
                        .lineLimit(1)
                }

                Spacer()

                DSStatusPill(status: offer.status)
            }

            if offer.status == .counterOffer && offer.contractorAcceptedCounter == true {
                DSBanner(kind: .success, message: "Contractor accepted your counter offer")
            } else if offer.status == .counterOffer {
                DSBanner(kind: .info, message: "Waiting for contractor response")
            }

            if !offer.message.isEmpty {
                Text(offer.message)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Divider().overlay(Color.divider)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: DS.Space.s) {
                        DSPriceText(
                            amount: offer.price,
                            tint: offer.counterPrice == nil ? .brand : .inkFaint
                        )

                        if let counterPrice = offer.counterPrice {
                            Image(systemName: "arrow.forward")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.inkFaint)
                            DSPriceText(amount: counterPrice, tint: .warning)
                        }
                    }

                    if offer.counterPrice != nil {
                        Text("Your counter offer")
                            .font(.dsCaption)
                            .foregroundStyle(Color.warning)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(offer.createdAt, style: .relative)
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkFaint)

                    if let respondedAt = offer.respondedAt {
                        Text("Responded \(respondedAt, style: .relative)")
                            .font(.dsCaption)
                            .foregroundStyle(Color.inkFaint)
                    }
                }
            }
        }
        .dsCard()
    }
}

#Preview {
    ReceivedOffersView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}

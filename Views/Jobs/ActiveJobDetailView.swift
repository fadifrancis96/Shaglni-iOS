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
        ZStack {
            Color.bgCanvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    header

                    acceptedOfferCard

                    descriptionCard

                    locationCard

                    if jobStatus == .inProgress {
                        inProgressCard
                    } else if jobStatus == .completed {
                        completedCard
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, DS.Space.l)
            }
        }
        .navigationTitle(L10n(key: "job.details").string)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCompletionPreview) {
            JobCompletionPreviewView(jobWithOffer: jobWithOffer)
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            DSCategoryIcon(category: jobWithOffer.job.category ?? .other, size: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(jobWithOffer.job.title)
                    .font(.dsTitle2)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.leading)

                HStack(spacing: DS.Space.s) {
                    DSStatusPill(status: jobStatus)
                    if let category = jobWithOffer.job.category {
                        DSTag(title: category.localized)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var acceptedOfferCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            DSBanner(kind: .success, message: L10n(key: "activeJobs.offerAcceptedTitle").string)

            HStack(alignment: .firstTextBaseline) {
                Text(L10n(key: "job.acceptedPrice").string + ":")
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                Spacer()
                DSPriceText(amount: finalPrice, font: .dsPriceLarge, tint: .success)
            }
        }
        .dsCard()
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            Text(L10n.Field.description.string)
                .font(.dsHeadline)
                .foregroundStyle(Color.ink)

            Text(jobWithOffer.job.description)
                .font(.dsBody)
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            Text(L10n.Field.location.string)
                .font(.dsHeadline)
                .foregroundStyle(Color.ink)

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.brand)
                Text(jobWithOffer.job.location)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
            }

            // Map Preview
            if let coordinate = jobWithOffer.job.coordinate {
                Map(position: .constant(.region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )))) {
                    Marker(jobWithOffer.job.title, coordinate: coordinate)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    private var inProgressCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack(spacing: DS.Space.s) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.warning)
                Text(L10n(key: "jobDetail.jobInProgress").string)
                    .font(.dsHeadline)
                    .foregroundStyle(Color.warning)
            }

            Text(L10n(key: "activeJobs.inProgressHint").string)
                .font(.dsSub)
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.l)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .fill(Color.warningSoft)
        )
    }

    private var completedCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            HStack(spacing: DS.Space.m) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.success)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.successSoft))

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n(key: "activeJobs.jobCompletedTitle").string)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.success)

                    Text(L10n(key: "activeJobs.completedByPoster").string)
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkMuted)
                }
            }

            Divider().overlay(Color.divider)

            VStack(alignment: .leading, spacing: DS.Space.s) {
                Text(L10n(key: "activeJobs.addToPortfolio").string)
                    .font(.dsHeadline)
                    .foregroundStyle(Color.ink)

                Text(L10n(key: "activeJobs.addToPortfolioHint").string)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
            }

            Button {
                showCompletionPreview = true
            } label: {
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(L10n(key: "activeJobs.addToProfile").string)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .flipsForRightToLeftLayoutDirection(true)
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())

            // Optional: Show if already in portfolio
            if isAlreadyInPortfolio {
                DSBanner(kind: .success, message: L10n(key: "activeJobs.alreadyInPortfolio").string)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.l)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(Color.success.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private var finalPrice: Double {
        jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
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

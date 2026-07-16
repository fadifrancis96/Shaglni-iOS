//
//  MyActiveJobsView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI

struct MyActiveJobsView: View {
    @EnvironmentObject var jobsRepo: JobsRepository
    @EnvironmentObject var offersRepo: OffersRepository
    @EnvironmentObject var portfolioRepo: PortfolioRepository
    @EnvironmentObject var localization: LocalizationManager
    @State private var selectedJob: JobWithOffer?
    @State private var newlyCompletedJob: JobWithOffer?
    @State private var showCompletionPreview = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        if activeJobs.isEmpty && completedJobs.isEmpty {
                            DSEmptyState(
                                systemImage: "briefcase.fill",
                                title: L10n.Empty.noActiveJobs.string,
                                message: L10n.Empty.noActiveJobsSubtitle.string
                            )
                        } else {
                            // Active Jobs Section
                            if !activeJobs.isEmpty {
                                VStack(spacing: DS.Space.m) {
                                    DSSectionHeader(title: L10n.JobStatus.inProgress.string)

                                    ForEach(activeJobs) { jobWithOffer in
                                        Button {
                                            selectedJob = jobWithOffer
                                        } label: {
                                            ActiveJobCard(jobWithOffer: jobWithOffer)
                                        }
                                        .buttonStyle(DSPressableStyle())
                                    }
                                }
                            }

                            // Completed Jobs Section
                            if !completedJobs.isEmpty {
                                VStack(spacing: DS.Space.m) {
                                    DSSectionHeader(title: L10n(key: "activeJobs.completedAddToProfile").string)

                                    ForEach(completedJobs) { jobWithOffer in
                                        CompletedJobCard(jobWithOffer: jobWithOffer) {
                                            // Open to job detail view so contractor can view the job first
                                            selectedJob = jobWithOffer
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.vertical, DS.Space.l)
                }
            }
            .navigationTitle(L10n.Action.myActiveJobs.string)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                maybeShowCompletionPreview()
            }
            .onChange(of: completedJobs) { _, _ in
                maybeShowCompletionPreview()
            }
            .sheet(item: $selectedJob) { jobWithOffer in
                NavigationStack {
                    ActiveJobDetailView(jobWithOffer: jobWithOffer)
                }
            }
            .sheet(isPresented: $showCompletionPreview) {
                if let completedJob = newlyCompletedJob {
                    JobCompletionPreviewView(jobWithOffer: completedJob)
                }
            }
        }
    }

    /// Live pairing of the contractor's won jobs with the offer that won them.
    private var jobsWithOffers: [JobWithOffer] {
        jobsRepo.myActiveJobs.compactMap { job in
            let offer = offersRepo.myOffers.first(where: { $0.id != nil && $0.id == job.acceptedOfferId })
                ?? offersRepo.myOffers.first(where: { $0.jobId == job.id })
            guard let offer else { return nil }
            return JobWithOffer(job: job, offer: offer)
        }
    }

    private var activeJobs: [JobWithOffer] {
        jobsWithOffers.filter { $0.job.status == .inProgress || $0.job.status == .open }
    }

    /// Completed jobs the contractor hasn't added to their portfolio yet.
    private var completedJobs: [JobWithOffer] {
        let portfolioJobIds = Set(portfolioRepo.myPortfolio.compactMap { $0.jobId })
        return jobsWithOffers.filter { jobWithOffer in
            guard jobWithOffer.job.status == .completed else { return false }
            guard let jobId = jobWithOffer.job.id else { return true }
            return !portfolioJobIds.contains(jobId)
        }
    }

    private func maybeShowCompletionPreview() {
        guard newlyCompletedJob == nil, let firstCompleted = completedJobs.first else { return }
        // Small delay to ensure UI is ready before presenting the sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard newlyCompletedJob == nil else { return }
            newlyCompletedJob = firstCompleted
            showCompletionPreview = true
        }
    }
}

private struct CompletedJobCard: View {
    let jobWithOffer: JobWithOffer
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .top, spacing: DS.Space.m) {
                DSCategoryIcon(category: jobWithOffer.job.category ?? .other)

                VStack(alignment: .leading, spacing: 4) {
                    Text(jobWithOffer.job.title)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let category = jobWithOffer.job.category {
                        Text(category.localized)
                            .font(.dsCaption)
                            .foregroundStyle(Color.inkMuted)
                    }
                }

                Spacer(minLength: DS.Space.s)

                DSStatusPill(status: JobStatus.completed)
            }

            Text(jobWithOffer.job.description)
                .font(.dsSub)
                .foregroundStyle(Color.inkMuted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack {
                Text(L10n(key: "activeJobs.finalPrice").string)
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
                Spacer()
                DSPriceText(amount: finalPrice, tint: .success)
            }

            Button(action: action) {
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text(L10n(key: "activeJobs.addToProfile").string)
                }
            }
            .buttonStyle(DSTonalButtonStyle(tint: .success, background: .successSoft))
        }
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
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .onTapGesture(perform: action)
    }

    private var finalPrice: Double {
        jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
    }
}

private struct ActiveJobCard: View {
    let jobWithOffer: JobWithOffer

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .top, spacing: DS.Space.m) {
                DSCategoryIcon(category: jobWithOffer.job.category ?? .other)

                VStack(alignment: .leading, spacing: 4) {
                    Text(jobWithOffer.job.title)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let category = jobWithOffer.job.category {
                        Text(category.localized)
                            .font(.dsCaption)
                            .foregroundStyle(Color.inkMuted)
                    }
                }

                Spacer(minLength: DS.Space.s)

                DSStatusPill(status: jobWithOffer.job.status)
            }

            Text(jobWithOffer.job.description)
                .font(.dsSub)
                .foregroundStyle(Color.inkMuted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 11))
                Text(jobWithOffer.job.location)
                    .lineLimit(1)
            }
            .font(.dsCaption)
            .foregroundStyle(Color.inkMuted)

            Divider().overlay(Color.divider)

            HStack(alignment: .firstTextBaseline) {
                Text(L10n(key: "job.acceptedPrice").string)
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
                Spacer()
                DSPriceText(amount: finalPrice)
            }
        }
        .dsCard()
    }

    private var finalPrice: Double {
        jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
    }
}

#Preview {
    MyActiveJobsView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
        .environmentObject(OffersRepository.shared)
        .environmentObject(PortfolioRepository.shared)
}

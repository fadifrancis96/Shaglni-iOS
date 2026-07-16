//
//  JobDetailView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct JobDetailView: View {
    let job: Job
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var jobsRepo: JobsRepository
    @EnvironmentObject var offersRepo: OffersRepository
    @State private var showOfferForm = false
    @State private var offers: [Offer] = []
    @State private var isLoadingOffers = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showMarkInProgressConfirmation = false
    @State private var showMarkDoneConfirmation = false
    @State private var offersListener: ListenerRegistration?
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss

    /// Live view of the job, backed by the repository snapshot listeners.
    /// Falls back to the value the view was constructed with.
    private var liveJob: Job {
        jobsRepo.myPostedJobs.first { $0.id == job.id }
            ?? jobsRepo.openJobs.first { $0.id == job.id }
            ?? jobsRepo.myActiveJobs.first { $0.id == job.id }
            ?? job
    }

    private var acceptedOffer: Offer? {
        offers.first(where: { $0.status == .accepted })
    }

    private var isOwner: Bool {
        authViewModel.isJobPoster && authViewModel.currentUser?.uid == job.createdBy
    }

    var body: some View {
        ZStack {
            Color.bgCanvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Space.xl) {
                    heroCard

                    descriptionCard

                    if let photoURLs = job.photoURLs, !photoURLs.isEmpty {
                        PhotoGalleryView(
                            photoURLs: photoURLs,
                            title: L10n(key: "job.requirements").string
                        )
                    }

                    locationCard

                    if let budget = job.budget {
                        budgetCard(budget)
                    }

                    if isOwner {
                        ownerStatusSection

                        offersSection
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.m)
                .padding(.bottom, DS.Space.xxl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Delete button for job owner
            if isOwner {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.danger)
                        }
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Submit Offer Button (for contractors)
            if authViewModel.isContractor && liveJob.status == .open {
                VStack(spacing: 0) {
                    Divider().overlay(Color.divider)

                    Button(action: { showOfferForm = true }) {
                        Text(L10n.Action.submitOffer.string)
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.vertical, DS.Space.m)
                }
                .background(Color.bgCanvas.ignoresSafeArea(edges: .bottom))
            }
        }
        .sheet(isPresented: $showOfferForm) {
            OfferFormView(job: job)
        }
        .alert(L10n(key: "jobDetail.deleteJob").string, isPresented: $showDeleteConfirmation) {
            Button(L10n.Common.cancel.string, role: .cancel) { }
            Button(L10n.Common.delete.string, role: .destructive) {
                deleteJob()
            }
        } message: {
            Text(L10n(key: "jobDetail.deleteConfirmMessage").string)
        }
        .alert(L10n.Action.markInProgress.string, isPresented: $showMarkInProgressConfirmation) {
            Button(L10n.Common.cancel.string, role: .cancel) { }
            Button(L10n.Action.markInProgress.string) {
                markJobInProgress()
            }
        } message: {
            Text(L10n(key: "jobDetail.markInProgressConfirmMessage").string)
        }
        .alert(L10n.Action.markDone.string, isPresented: $showMarkDoneConfirmation) {
            Button(L10n.Common.cancel.string, role: .cancel) { }
            Button(L10n.Action.markDone.string) {
                markJobAsDone()
            }
        } message: {
            Text(L10n(key: "jobDetail.markDoneConfirmMessage").string)
        }
        .alert(L10n.Common.error.string, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button(L10n(key: "common.ok").string, role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            startOffersListener()
        }
        .onDisappear {
            offersListener?.remove()
            offersListener = nil
        }
    }

    // MARK: - Sections

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .top, spacing: DS.Space.m) {
                DSCategoryIcon(category: job.category ?? .other, size: 52)

                VStack(alignment: .leading, spacing: 6) {
                    Text(job.title)
                        .font(.dsTitle2)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: DS.Space.s) {
                        DSStatusPill(status: liveJob.status)

                        if let category = job.category {
                            DSTag(title: category.localized, systemImage: "tag.fill")
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            Divider().overlay(Color.divider)

            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .semibold))
                Text(L10n(key: "jobDetail.posted").string)
                Text(job.datePosted, style: .date)
            }
            .font(.dsCaption)
            .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            Text(L10n.Field.description.string)
                .font(.dsCaptionBold)
                .foregroundStyle(Color.inkMuted)
                .textCase(.uppercase)

            Text(job.description)
                .font(.dsSub)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            Text(L10n.Field.location.string)
                .font(.dsCaptionBold)
                .foregroundStyle(Color.inkMuted)
                .textCase(.uppercase)

            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brand)
                Text(job.location)
                    .font(.dsSub)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.leading)
            }

            // Map Preview
            if let coordinate = job.coordinate {
                Map(position: .constant(.region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )))) {
                    Marker(job.title, coordinate: coordinate)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    private func budgetCard(_ budget: Double) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            Text(L10n.Field.budget.string)
                .font(.dsCaptionBold)
                .foregroundStyle(Color.inkMuted)
                .textCase(.uppercase)

            DSPriceText(amount: budget, font: .dsPriceLarge)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    // MARK: - Owner status management

    @ViewBuilder
    private var ownerStatusSection: some View {
        if liveJob.status == .open {
            // Check if there's an accepted offer
            if let accepted = acceptedOffer {
                VStack(spacing: DS.Space.m) {
                    acceptedOfferCard(accepted)

                    Button(action: { showMarkInProgressConfirmation = true }) {
                        Label(L10n.Action.markInProgress.string, systemImage: "hammer.fill")
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                }
            }
        } else if liveJob.status == .inProgress {
            VStack(spacing: DS.Space.m) {
                statusInfoCard(
                    systemImage: "clock.fill",
                    title: L10n(key: "jobDetail.jobInProgress").string,
                    message: L10n(key: "jobDetail.inProgressHint").string,
                    tint: .warning,
                    background: .warningSoft
                )

                Button(action: { showMarkDoneConfirmation = true }) {
                    Label(L10n.Action.markDone.string, systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }
        } else if liveJob.status == .completed {
            statusInfoCard(
                systemImage: "checkmark.seal.fill",
                title: L10n(key: "jobDetail.jobCompleted").string,
                message: L10n(key: "jobDetail.completedHint").string,
                tint: .success,
                background: .successSoft
            )
        }
    }

    private func acceptedOfferCard(_ accepted: Offer) -> some View {
        let displayPrice = accepted.finalPrice ?? accepted.counterPrice ?? accepted.price

        return VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack(spacing: DS.Space.s) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.success)
                Text(L10n(key: "jobDetail.offerAccepted").string)
                    .font(.dsHeadline)
                    .foregroundStyle(Color.success)
            }

            HStack {
                Text(L10n(key: "job.acceptedPrice").string + ":")
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                Spacer()
                DSPriceText(amount: displayPrice, tint: .success)
            }

            Text(L10n(key: "jobDetail.byContractor").format(accepted.contractorName))
                .font(.dsCaption)
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.l)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(Color.successSoft)
        )
    }

    private func statusInfoCard(
        systemImage: String,
        title: String,
        message: String,
        tint: Color,
        background: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack(spacing: DS.Space.s) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.dsHeadline)
                    .foregroundStyle(tint)
            }

            Text(message)
                .font(.dsCaption)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.l)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(background)
        )
    }

    // MARK: - Offers

    private var offersSection: some View {
        VStack(spacing: DS.Space.m) {
            DSSectionHeader(title: L10n.Section.offersCount(offers.count))

            if isLoadingOffers {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Space.xl)
            } else if offers.isEmpty {
                DSEmptyState(
                    systemImage: "doc.text",
                    title: L10n.Empty.noOffers.string,
                    message: L10n(key: "jobDetail.waitForOffers").string
                )
                .dsCard()
            } else {
                ForEach(offers) { offer in
                    NavigationLink(destination: OfferDetailView(offer: offer, jobId: job.id ?? "")) {
                        OfferCardView(offer: offer)
                    }
                    .buttonStyle(DSPressableStyle())
                }
            }
        }
    }

    // MARK: - Data

    private func startOffersListener() {
        guard offersListener == nil, let jobId = job.id else { return }
        guard isOwner else { return }

        isLoadingOffers = true
        offersListener = offersRepo.listen(jobId: jobId) { fetchedOffers in
            isLoadingOffers = false
            offers = fetchedOffers
        }
    }

    private func markJobInProgress() {
        guard let jobId = job.id else { return }

        Task {
            do {
                try await jobsRepo.updateStatus(jobId: jobId, status: .inProgress)
            } catch {
                errorMessage = AppError(error).errorDescription
            }
        }
    }

    private func markJobAsDone() {
        guard let jobId = job.id else { return }

        Task {
            do {
                try await jobsRepo.updateStatus(jobId: jobId, status: .completed)
            } catch {
                errorMessage = AppError(error).errorDescription
            }
        }
    }

    private func deleteJob() {
        guard let jobId = job.id else { return }

        isDeleting = true
        Task {
            do {
                try await jobsRepo.delete(jobId: jobId)
                isDeleting = false
                dismiss()
            } catch {
                isDeleting = false
                errorMessage = AppError(error).errorDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        JobDetailView(job: Job(
            id: "1",
            title: "Fix Kitchen Plumbing",
            description: "Need a plumber to fix leaking pipes in the kitchen",
            location: "Riyadh, Saudi Arabia",
            latitude: 24.7136,
            longitude: 46.6753,
            datePosted: Date(),
            createdBy: "user123",
            status: .open,
            category: .plumbing,
            budget: 500
        ))
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
        .environmentObject(OffersRepository.shared)
    }
}

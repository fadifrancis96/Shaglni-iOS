//
//  JobDetailView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI
import MapKit
import Combine

struct JobDetailView: View {
    let job: Job
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var showOfferForm = false
    @State private var offers: [Offer] = []
    @State private var isLoadingOffers = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var currentJobStatus: JobStatus
    @State private var showMarkInProgressConfirmation = false
    @State private var showMarkDoneConfirmation = false
    @State private var isUpdatingStatus = false
    @State private var acceptedOffer: Offer?
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase

    init(job: Job) {
        self.job = job
        _currentJobStatus = State(initialValue: job.status)
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
                            title: "Job Requirements"
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
            if authViewModel.isContractor && currentJobStatus == .open {
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
        .alert("Delete Job", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteJob()
            }
        } message: {
            Text("Are you sure you want to delete this job? This will also delete all associated offers. This action cannot be undone.")
        }
        .alert("Mark Job In Progress", isPresented: $showMarkInProgressConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Mark In Progress") {
                markJobInProgress()
            }
        } message: {
            Text("This will remove the job from public listings and mark it as in progress. Continue?")
        }
        .alert("Mark Job as Done", isPresented: $showMarkDoneConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Mark as Done") {
                markJobAsDone()
            }
        } message: {
            Text("Mark this job as completed? This action cannot be undone.")
        }
        .onAppear {
            loadOffers()
            refreshJobStatus()
        }
        .onChange(of: scenePhase) { newPhase in
            // Refresh when app becomes active
            if newPhase == .active {
                loadOffers()
                refreshJobStatus()
            }
        }
        .onChange(of: offers) { _ in
            // Update accepted offer when offers change
            acceptedOffer = offers.first(where: { $0.status == .accepted })
        }
        .refreshable {
            // Pull to refresh
            loadOffers()
            refreshJobStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OfferStatusUpdated"))) { _ in
            // Refresh when offer status changes
            print("🔄 Received OfferStatusUpdated notification - refreshing offers and job status")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Small delay to ensure Firestore has updated
                loadOffers()
                refreshJobStatus()
            }
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
                        DSStatusPill(status: currentJobStatus)

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
                Text("Posted")
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
            Text(localization.localized("description"))
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
            Text(localization.localized("location"))
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
            Text(localization.localized("budget"))
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
        if currentJobStatus == .open {
            // Check if there's an accepted offer (check both offers array and acceptedOffer state)
            let accepted = acceptedOffer ?? offers.first(where: { $0.status == .accepted })
            if let accepted = accepted {
                VStack(spacing: DS.Space.m) {
                    acceptedOfferCard(accepted)

                    Button(action: { showMarkInProgressConfirmation = true }) {
                        Label(L10n.Action.markInProgress.string, systemImage: "hammer.fill")
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                }
            }
        } else if currentJobStatus == .inProgress {
            VStack(spacing: DS.Space.m) {
                statusInfoCard(
                    systemImage: "clock.fill",
                    title: "Job In Progress",
                    message: "The job is currently being worked on. Mark as done when the work is completed.",
                    tint: .warning,
                    background: .warningSoft
                )

                Button(action: { showMarkDoneConfirmation = true }) {
                    Label(L10n.Action.markDone.string, systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }
        } else if currentJobStatus == .completed {
            statusInfoCard(
                systemImage: "checkmark.seal.fill",
                title: "Job Completed",
                message: "This job has been marked as completed.",
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
                Text("Offer Accepted")
                    .font(.dsHeadline)
                    .foregroundStyle(Color.success)
            }

            HStack {
                Text("Accepted Price:")
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                Spacer()
                DSPriceText(amount: displayPrice, tint: .success)
            }

            Text("By: \(accepted.contractorName)")
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
                    message: "Wait for contractors to submit offers"
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

    private func loadOffers() {
        guard let jobId = job.id else { return }
        guard authViewModel.isJobPoster && authViewModel.currentUser?.uid == job.createdBy else { return }

        isLoadingOffers = true
        FirestoreService.shared.fetchOffersForJob(jobId: jobId) { result in
            isLoadingOffers = false
            switch result {
            case .success(let fetchedOffers):
                offers = fetchedOffers
                acceptedOffer = fetchedOffers.first(where: { $0.status == .accepted })
                print("📋 Loaded \(fetchedOffers.count) offers. Accepted offer: \(acceptedOffer != nil ? "Yes" : "No")")
                if let accepted = acceptedOffer {
                    print("✅ Found accepted offer from \(accepted.contractorName) for ₪\(accepted.price)")
                }
            case .failure(let error):
                print("Error loading offers: \(error.localizedDescription)")
            }
        }
    }

    private func refreshJobStatus() {
        guard let jobId = job.id else { return }

        FirestoreService.shared.fetchJob(jobId: jobId) { result in
            switch result {
            case .success(let updatedJob):
                currentJobStatus = updatedJob.status
                print("✅ Job status refreshed: \(updatedJob.status.rawValue)")
            case .failure(let error):
                print("❌ Error refreshing job status: \(error.localizedDescription)")
            }
        }
    }

    private func markJobInProgress() {
        guard let jobId = job.id else { return }

        isUpdatingStatus = true
        FirestoreService.shared.updateJobStatus(jobId: jobId, status: .inProgress) { result in
            isUpdatingStatus = false
            switch result {
            case .success:
                currentJobStatus = .inProgress
                refreshJobStatus()
            case .failure(let error):
                print("Error updating job status: \(error.localizedDescription)")
            }
        }
    }

    private func markJobAsDone() {
        guard let jobId = job.id else { return }

        isUpdatingStatus = true
        FirestoreService.shared.updateJobStatus(jobId: jobId, status: .completed) { result in
            isUpdatingStatus = false
            switch result {
            case .success:
                currentJobStatus = .completed
                refreshJobStatus()

                // Notify contractor that job is completed
                NotificationCenter.default.post(
                    name: NSNotification.Name("JobCompleted"),
                    object: jobId
                )
            case .failure(let error):
                print("Error updating job status: \(error.localizedDescription)")
            }
        }
    }

    private func deleteJob() {
        guard let jobId = job.id else { return }

        isDeleting = true
        FirestoreService.shared.deleteJob(jobId: jobId) { result in
            isDeleting = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                print("Error deleting job: \(error.localizedDescription)")
                // Could add an error alert here if needed
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
        .environmentObject(LocalizationManager())
    }
}

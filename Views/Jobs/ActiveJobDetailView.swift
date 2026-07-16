//
//  ActiveJobDetailView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI
import MapKit
import Combine

struct ActiveJobDetailView: View {
    let jobWithOffer: JobWithOffer
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var jobStatus: JobStatus
    @State private var showCompletionPreview = false

    init(jobWithOffer: JobWithOffer) {
        self.jobWithOffer = jobWithOffer
        _jobStatus = State(initialValue: jobWithOffer.job.status)
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
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshJobStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("JobCompleted"))) { notification in
            if let completedJobId = notification.object as? String,
               completedJobId == jobWithOffer.job.id {
                refreshJobStatus()
                // Don't auto-show preview - let contractor view the job first and decide
            }
        }
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
            DSBanner(kind: .success, message: "Your Offer Was Accepted")

            HStack(alignment: .firstTextBaseline) {
                Text("Accepted Price:")
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
            Text(localization.localized("description"))
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
            Text(localization.localized("location"))
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
                Text("Job In Progress")
                    .font(.dsHeadline)
                    .foregroundStyle(Color.warning)
            }

            Text("The job poster has marked this job as in progress. Complete the work and wait for them to mark it as done.")
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
                    Text("Job Completed!")
                        .font(.dsHeadline)
                        .foregroundStyle(Color.success)

                    Text("The job poster has marked this job as completed")
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkMuted)
                }
            }

            Divider().overlay(Color.divider)

            VStack(alignment: .leading, spacing: DS.Space.s) {
                Text("Add to Your Portfolio")
                    .font(.dsHeadline)
                    .foregroundStyle(Color.ink)

                Text("Showcase this completed work on your profile by adding photos and creating a before/after comparison. This will help potential clients see your quality of work.")
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
            }

            Button {
                showCompletionPreview = true
            } label: {
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add to Profile")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .flipsForRightToLeftLayoutDirection(true)
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())

            // Optional: Show if already in portfolio
            checkIfAlreadyInPortfolio { isInPortfolio in
                if isInPortfolio {
                    DSBanner(kind: .success, message: "This job is already in your portfolio")
                }
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

    private func refreshJobStatus() {
        guard let jobId = jobWithOffer.job.id else { return }

        FirestoreService.shared.fetchJob(jobId: jobId) { result in
            switch result {
            case .success(let updatedJob):
                jobStatus = updatedJob.status
                // Don't auto-show preview - let contractor decide when to add
            case .failure(let error):
                print("Error refreshing job status: \(error.localizedDescription)")
            }
        }
    }

    @ViewBuilder
    private func checkIfAlreadyInPortfolio(@ViewBuilder content: @escaping (Bool) -> some View) -> some View {
        Group {
            if let jobId = jobWithOffer.job.id,
               let contractorId = authViewModel.currentUser?.uid {
                CheckPortfolioView(jobId: jobId, contractorId: contractorId) { isInPortfolio in
                    content(isInPortfolio)
                }
            } else {
                content(false)
            }
        }
    }
}

// Helper view to check if job is in portfolio
private struct CheckPortfolioView<Content: View>: View {
    let jobId: String
    let contractorId: String
    let content: (Bool) -> Content
    @State private var isInPortfolio = false
    @State private var hasChecked = false

    var body: some View {
        Group {
            if hasChecked {
                content(isInPortfolio)
            } else {
                EmptyView()
            }
        }
        .onAppear {
            checkPortfolio()
        }
    }

    private func checkPortfolio() {
        FirestoreService.shared.fetchCompletedJobs(contractorId: contractorId) { result in
            switch result {
            case .success(let jobs):
                isInPortfolio = jobs.contains(where: { $0.jobId == jobId })
                hasChecked = true
            case .failure:
                hasChecked = true
            }
        }
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
        .environmentObject(LocalizationManager())
    }
}

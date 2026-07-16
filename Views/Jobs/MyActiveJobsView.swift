//
//  MyActiveJobsView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI

struct MyActiveJobsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var activeJobs: [JobWithOffer] = []
    @State private var completedJobs: [JobWithOffer] = []
    @State private var isLoading = true
    @State private var selectedJob: JobWithOffer?
    @State private var showJobDetail = false
    @State private var newlyCompletedJob: JobWithOffer?
    @State private var showCompletionPreview = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        if isLoading && activeJobs.isEmpty && completedJobs.isEmpty {
                            ForEach(0..<3, id: \.self) { _ in
                                JobCardPlaceholder()
                            }
                        } else if !isLoading && activeJobs.isEmpty && completedJobs.isEmpty {
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
                                            showJobDetail = true
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
                                    DSSectionHeader(title: "Completed - Add to Profile")

                                    ForEach(completedJobs) { jobWithOffer in
                                        CompletedJobCard(jobWithOffer: jobWithOffer) {
                                            // Open to job detail view so contractor can view the job first
                                            selectedJob = jobWithOffer
                                            showJobDetail = true
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
            .refreshable {
                loadActiveJobs()
            }
            .onAppear {
                loadActiveJobs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("JobCompleted"))) { _ in
                // Refresh when a job is completed
                loadActiveJobs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OfferStatusUpdated"))) { _ in
                // Refresh when offer status changes
                loadActiveJobs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CompletedJobAdded"))) { _ in
                // Refresh when a job is added to portfolio
                loadActiveJobs()
            }
            .sheet(item: $selectedJob) { jobWithOffer in
                NavigationStack {
                    ActiveJobDetailView(jobWithOffer: jobWithOffer)
                        .onDisappear {
                            // Refresh when returning from job detail
                            loadActiveJobs()
                        }
                }
            }
            .sheet(isPresented: $showCompletionPreview) {
                if let completedJob = newlyCompletedJob {
                    JobCompletionPreviewView(jobWithOffer: completedJob)
                }
            }
        }
    }

    private func loadActiveJobs() {
        guard let contractorId = authViewModel.currentUser?.uid else {
            print("❌ No contractor ID available")
            return
        }

        print("🔍 Loading active jobs for contractor: \(contractorId)")
        isLoading = true

        // Fetch all jobs where contractor has an accepted offer
        FirestoreService.shared.fetchJobsWithAcceptedOffer(contractorId: contractorId) { [self] result in
            switch result {
            case .success(let jobs):
                print("📊 Fetched \(jobs.count) jobs total")

                // Separate active and completed jobs
                activeJobs = jobs.filter { $0.job.status == .inProgress || $0.job.status == .open }
                let allCompletedJobs = jobs.filter { $0.job.status == .completed }

                // Fetch portfolio jobs to filter out already added ones
                FirestoreService.shared.fetchCompletedJobs(contractorId: contractorId) { portfolioResult in
                    isLoading = false
                    switch portfolioResult {
                    case .success(let portfolioJobs):
                        // Get set of job IDs that are already in portfolio
                        let portfolioJobIds = Set(portfolioJobs.compactMap { $0.jobId })

                        // Filter out completed jobs that are already in portfolio
                        completedJobs = allCompletedJobs.filter { jobWithOffer in
                            guard let jobId = jobWithOffer.job.id else { return true }
                            return !portfolioJobIds.contains(jobId)
                        }

                        print("✅ Active jobs: \(activeJobs.count), Completed (not in portfolio): \(completedJobs.count)")

                        // Check if there's a newly completed job to show preview
                        if let firstCompleted = completedJobs.first,
                           newlyCompletedJob == nil {
                            // Small delay to ensure UI is ready
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                newlyCompletedJob = firstCompleted
                                showCompletionPreview = true
                            }
                        }
                    case .failure(let error):
                        // If we can't fetch portfolio, show all completed jobs
                        completedJobs = allCompletedJobs
                        isLoading = false
                        print("Error loading portfolio: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                isLoading = false
                print("Error loading active jobs: \(error.localizedDescription)")
            }
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
                Text("Final Price")
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
                Spacer()
                DSPriceText(amount: finalPrice, tint: .success)
            }

            Button(action: action) {
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Add to Profile")
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
                Text("Accepted Price")
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
        .environmentObject(LocalizationManager())
}

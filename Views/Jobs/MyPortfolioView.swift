//
//  MyPortfolioView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI

struct MyPortfolioView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var portfolioJobs: [CompletedJob] = [] // Jobs already in profile
    @State private var completedButNotAdded: [JobWithOffer] = [] // Jobs completed but not yet added
    @State private var isLoading = true
    @State private var selectedJob: JobWithOffer?
    @State private var showCompletionPreview = false
    @State private var selectedCompletedJob: CompletedJob?
    @State private var isEditMode = false
    @State private var jobToDelete: CompletedJob?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: DS.Space.m),
        GridItem(.flexible(), spacing: DS.Space.m)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.Action.myPortfolio.string)
                                .font(.dsTitle)
                                .foregroundStyle(Color.ink)

                            Text("Showcase your completed work")
                                .font(.dsSub)
                                .foregroundStyle(Color.inkMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, DS.Space.s)

                        // Portfolio Jobs (Already Added)
                        VStack(spacing: DS.Space.m) {
                            DSSectionHeader(
                                title: "Portfolio Items",
                                actionTitle: portfolioJobs.isEmpty ? nil : (isEditMode ? L10n.Common.done.string : L10n.Common.edit.string),
                                action: portfolioJobs.isEmpty ? nil : {
                                    withAnimation {
                                        isEditMode.toggle()
                                    }
                                }
                            )

                            if isLoading {
                                LazyVGrid(columns: gridColumns, spacing: DS.Space.m) {
                                    ForEach(0..<4, id: \.self) { _ in
                                        PortfolioCardPlaceholder()
                                    }
                                }
                            } else if portfolioJobs.isEmpty {
                                DSEmptyState(
                                    systemImage: "photo.stack.fill",
                                    title: "No Portfolio Items Yet",
                                    message: "Add completed jobs to showcase your work to potential clients"
                                )
                            } else {
                                LazyVGrid(columns: gridColumns, spacing: DS.Space.m) {
                                    ForEach(portfolioJobs) { job in
                                        PortfolioJobCard(
                                            job: job,
                                            isEditMode: isEditMode,
                                            onDelete: {
                                                jobToDelete = job
                                                showDeleteConfirmation = true
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.bottom, DS.Space.xxl)
                }
            }
            .navigationTitle(L10n.Action.myPortfolio.string)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                loadData()
            }
            .onAppear {
                loadData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CompletedJobAdded"))) { _ in
                loadData()
            }
            .sheet(isPresented: $showCompletionPreview) {
                if let job = selectedJob {
                    JobCompletionPreviewView(jobWithOffer: job)
                        .onDisappear {
                            // Refresh when returning
                            loadData()
                        }
                }
            }
            .sheet(item: $selectedCompletedJob) { job in
                PortfolioJobDetailView(job: job)
            }
            .alert("Delete Portfolio Item", isPresented: $showDeleteConfirmation) {
                Button(L10n.Common.cancel.string, role: .cancel) {
                    jobToDelete = nil
                }
                Button(L10n.Common.delete.string, role: .destructive) {
                    if let job = jobToDelete {
                        deletePortfolioJob(job)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this portfolio item? This will also delete all associated photos. This action cannot be undone.")
            }
        }
    }

    private func loadData() {
        guard let contractorId = authViewModel.currentUser?.uid else { return }

        isLoading = true

        // Load portfolio jobs (already added)
        FirestoreService.shared.fetchCompletedJobs(contractorId: contractorId) { [self] result in
            switch result {
            case .success(let jobs):
                portfolioJobs = jobs

                // Now load completed jobs that aren't in portfolio yet
                FirestoreService.shared.fetchJobsWithAcceptedOffer(contractorId: contractorId) { result in
                    isLoading = false
                    switch result {
                    case .success(let jobsWithOffers):
                        let completedJobs = jobsWithOffers.filter { $0.job.status == .completed }

                        // Filter out jobs that are already in portfolio
                        let portfolioJobIds = Set(portfolioJobs.compactMap { $0.jobId })
                        completedButNotAdded = completedJobs.filter { jobWithOffer in
                            guard let jobId = jobWithOffer.job.id else { return false }
                            return !portfolioJobIds.contains(jobId)
                        }
                    case .failure(let error):
                        print("Error loading completed jobs: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                isLoading = false
                print("Error loading portfolio: \(error.localizedDescription)")
            }
        }
    }

    private func deletePortfolioJob(_ job: CompletedJob) {
        guard !isDeleting else { return }
        isDeleting = true

        Task {
            var photoURLs = job.images
            if let grid = job.beforeAfterGridImage { photoURLs.append(grid) }
            await PhotoUploadService.shared.deleteAll(urls: photoURLs)

            do {
                try await PortfolioRepository.shared.delete(job)
                await MainActor.run {
                    portfolioJobs.removeAll { $0.id == job.id }
                    isDeleting = false
                    jobToDelete = nil
                }
            } catch {
                AppLogger.portfolio.error("Failed to delete portfolio item: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    isDeleting = false
                    jobToDelete = nil
                }
            }
        }
    }
}

private struct PortfolioJobCard: View {
    let job: CompletedJob
    var isEditMode: Bool = false
    var onDelete: (() -> Void)? = nil

    private var coverImageURL: String? {
        job.images.first ?? job.beforeAfterGridImage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            // Cover image
            ZStack(alignment: .topTrailing) {
                Group {
                    if let urlString = coverImageURL {
                        AsyncImage(url: URL(string: urlString)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.surfaceAlt
                        }
                    } else {
                        ZStack {
                            Color.surfaceAlt
                            DSCategoryIcon(category: job.category ?? .other, size: 40)
                        }
                    }
                }
                .frame(height: 110)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous))

                if isEditMode {
                    Button {
                        onDelete?()
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.danger)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Color.dangerSoft))
                    }
                    .padding(DS.Space.xs)
                } else if job.images.count > 1 {
                    HStack(spacing: 3) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 9, weight: .semibold))
                        Text("\(job.images.count)")
                            .font(.dsMicro)
                    }
                    .foregroundStyle(Color.onBrand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.brand.opacity(0.85)))
                    .padding(DS.Space.xs)
                }
            }

            Text(job.title)
                .font(.dsHeadline)
                .foregroundStyle(Color.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let category = job.category {
                DSTag(title: category.localized)
            }

            Spacer(minLength: 0)

            if let price = job.finalPrice {
                DSPriceText(amount: price, tint: .success)
            }

            Text(job.completedDate, style: .date)
                .font(.dsCaption)
                .foregroundStyle(Color.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard(padding: DS.Space.m)
    }
}

private struct PortfolioCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            RoundedRectangle(cornerRadius: DS.Radius.thumb).fill(Color.surfaceAlt)
                .frame(height: 110)
                .frame(maxWidth: .infinity)
            RoundedRectangle(cornerRadius: 4).fill(Color.surfaceAlt)
                .frame(width: 110, height: 14)
            RoundedRectangle(cornerRadius: 4).fill(Color.surfaceAlt)
                .frame(width: 70, height: 10)
        }
        .dsCard(padding: DS.Space.m)
        .dsSkeleton(when: true)
    }
}

private struct PortfolioJobDetailView: View {
    let job: CompletedJob
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Space.xl) {
                        VStack(alignment: .leading, spacing: DS.Space.s) {
                            Text(job.title)
                                .font(.dsTitle2)
                                .foregroundStyle(Color.ink)

                            Text(job.description)
                                .font(.dsBody)
                                .foregroundStyle(Color.inkMuted)
                        }

                        // All Images
                        if !job.images.isEmpty {
                            VStack(alignment: .leading, spacing: DS.Space.m) {
                                Text("Photos")
                                    .font(.dsHeadline)
                                    .foregroundStyle(Color.ink)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Space.m) {
                                    ForEach(job.images, id: \.self) { imageUrl in
                                        AsyncImage(url: URL(string: imageUrl)) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Color.surfaceAlt
                                        }
                                        .frame(height: 120)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous))
                                    }
                                }
                            }
                        }

                        // Before/After Grid
                        if let gridImageUrl = job.beforeAfterGridImage {
                            VStack(alignment: .leading, spacing: DS.Space.m) {
                                Text("Before & After")
                                    .font(.dsHeadline)
                                    .foregroundStyle(Color.ink)

                                AsyncImage(url: URL(string: gridImageUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    Color.surfaceAlt
                                        .frame(height: 300)
                                }
                                .frame(maxHeight: 400)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous))
                            }
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.vertical, DS.Space.l)
                }
            }
            .navigationTitle("Portfolio Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.done.string) {
                        dismiss()
                    }
                    .foregroundStyle(Color.brand)
                }
            }
        }
    }
}

#Preview {
    MyPortfolioView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}

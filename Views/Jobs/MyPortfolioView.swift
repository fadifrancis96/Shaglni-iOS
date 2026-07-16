//
//  MyPortfolioView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI

struct MyPortfolioView: View {
    @EnvironmentObject var portfolioRepo: PortfolioRepository
    @EnvironmentObject var localization: LocalizationManager
    @State private var selectedCompletedJob: CompletedJob?
    @State private var isEditMode = false
    @State private var jobToDelete: CompletedJob?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private let gridColumns = [
        GridItem(.flexible(), spacing: DS.Space.m),
        GridItem(.flexible(), spacing: DS.Space.m)
    ]

    private var portfolioJobs: [CompletedJob] {
        portfolioRepo.myPortfolio
    }

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

                            Text(L10n(key: "portfolio.subtitle").string)
                                .font(.dsSub)
                                .foregroundStyle(Color.inkMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, DS.Space.s)

                        // Portfolio Jobs (Already Added)
                        VStack(spacing: DS.Space.m) {
                            DSSectionHeader(
                                title: L10n(key: "portfolio.items").string,
                                actionTitle: portfolioJobs.isEmpty ? nil : (isEditMode ? L10n.Common.done.string : L10n.Common.edit.string),
                                action: portfolioJobs.isEmpty ? nil : {
                                    withAnimation {
                                        isEditMode.toggle()
                                    }
                                }
                            )

                            if portfolioJobs.isEmpty {
                                DSEmptyState(
                                    systemImage: "photo.stack.fill",
                                    title: L10n(key: "portfolio.empty.title").string,
                                    message: L10n(key: "portfolio.empty.subtitle").string
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
            .sheet(item: $selectedCompletedJob) { job in
                PortfolioJobDetailView(job: job)
            }
            .alert(L10n(key: "portfolio.delete.title").string, isPresented: $showDeleteConfirmation) {
                Button(L10n.Common.cancel.string, role: .cancel) {
                    jobToDelete = nil
                }
                Button(L10n.Common.delete.string, role: .destructive) {
                    if let job = jobToDelete {
                        deletePortfolioJob(job)
                    }
                }
            } message: {
                Text(L10n(key: "portfolio.delete.message").string)
            }
            .alert(L10n.Common.error.string, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button(L10n(key: "common.ok").string, role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
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
                try await portfolioRepo.delete(job)
                await MainActor.run {
                    isDeleting = false
                    jobToDelete = nil
                }
            } catch {
                AppLogger.portfolio.error("Failed to delete portfolio item: \(error.localizedDescription, privacy: .public)")
                await MainActor.run {
                    errorMessage = AppError(error).errorDescription
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
                                Text(L10n(key: "portfolio.photos").string)
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
                                Text(L10n(key: "portfolio.beforeAfter").string)
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
            .navigationTitle(L10n(key: "portfolio.item").string)
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
        .environmentObject(LocalizationManager.shared)
        .environmentObject(PortfolioRepository.shared)
}

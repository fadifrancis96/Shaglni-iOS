//
//  MyPortfolioView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI

struct MyPortfolioView: View {
    @EnvironmentObject var portfolioRepo: PortfolioRepository
    @State private var selectedCompletedJob: CompletedJob?
    @State private var isEditMode = false
    @State private var jobToDelete: CompletedJob?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var portfolioJobs: [CompletedJob] {
        portfolioRepo.myPortfolio
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.Action.myPortfolio.string)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(L10n(key: "portfolio.subtitle").string)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Portfolio Jobs (Already Added)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(L10n(key: "portfolio.items").string)
                                .font(.headline)
                            
                            Spacer()
                            
                            if !portfolioJobs.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        isEditMode.toggle()
                                    }
                                }) {
                                    Text(isEditMode ? L10n.Common.done.string : L10n.Common.edit.string)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if portfolioJobs.isEmpty {
                            EmptyStateView(
                                icon: "photo.stack.fill",
                                title: L10n(key: "portfolio.empty.title").string,
                                subtitle: L10n(key: "portfolio.empty.subtitle").string
                            )
                        } else {
                            ForEach(portfolioJobs) { job in
                                PortfolioJobCard(
                                    job: job,
                                    isEditMode: isEditMode,
                                    onDelete: {
                                        jobToDelete = job
                                        showDeleteConfirmation = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom)
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

struct PortfolioJobCard: View {
    let job: CompletedJob
    var isEditMode: Bool = false
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let category = job.category {
                        Text(category.localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if isEditMode {
                        Button(action: {
                            onDelete?()
                        }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text(L10n(key: "portfolio.inPortfolio").string)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            Text(job.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Images Preview
            if !job.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(job.images.prefix(3), id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(8)
                        }
                        
                        if job.images.count > 3 {
                            Text(L10n(key: "portfolio.moreCount").format(job.images.count - 3))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 80, height: 80)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Before/After Grid Preview
            if let gridImageUrl = job.beforeAfterGridImage {
                AsyncImage(url: URL(string: gridImageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Color.gray.opacity(0.3)
                        .frame(height: 150)
                }
                .frame(maxHeight: 150)
                .cornerRadius(8)
            }
            
            HStack {
                if let price = job.finalPrice {
                    Text(Money.string(price))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                Spacer()

                Text(L10n(key: "portfolio.completedDate").format(formatDate(job.completedDate)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            // Could add detail view later
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct PortfolioJobDetailView: View {
    let job: CompletedJob
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(job.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(job.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // All Images
                    if !job.images.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n(key: "portfolio.photos").string)
                                .font(.headline)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(job.images, id: \.self) { imageUrl in
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
                                    }
                                    .frame(height: 120)
                                    .clipped()
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Before/After Grid
                    if let gridImageUrl = job.beforeAfterGridImage {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n(key: "portfolio.beforeAfter").string)
                                .font(.headline)
                            
                            AsyncImage(url: URL(string: gridImageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                                    .frame(height: 300)
                            }
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(L10n(key: "portfolio.item").string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.done.string) {
                        dismiss()
                    }
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


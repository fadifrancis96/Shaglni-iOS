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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Portfolio")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Showcase your completed work")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Portfolio Jobs (Already Added)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Portfolio Items")
                                .font(.headline)
                            
                            Spacer()
                            
                            if !portfolioJobs.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        isEditMode.toggle()
                                    }
                                }) {
                                    Text(isEditMode ? "Done" : "Edit")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if portfolioJobs.isEmpty {
                            EmptyStateView(
                                icon: "photo.stack.fill",
                                title: "No Portfolio Items Yet",
                                subtitle: "Add completed jobs to showcase your work to potential clients"
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
            .navigationTitle("My Portfolio")
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
                Button("Cancel", role: .cancel) {
                    jobToDelete = nil
                }
                Button("Delete", role: .destructive) {
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

struct CompletedJobToAddCard: View {
    let jobWithOffer: JobWithOffer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(jobWithOffer.job.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let category = jobWithOffer.job.category {
                        Text(category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                    Text("Add")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            Text(jobWithOffer.job.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                let finalPrice = jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
                Text("Price: ₪\(String(format: "%.0f", finalPrice))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
                
                Label(jobWithOffer.job.location, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Tap to add photos and create before/after comparison")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.05), Color.blue.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(12)
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
                        Text(category.rawValue)
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
                            Text("In Portfolio")
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
                            Text("+\(job.images.count - 3) more")
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
                    Text("₪\(String(format: "%.0f", price))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text("Completed: \(formatDate(job.completedDate))")
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
                            Text("Photos")
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
                            Text("Before & After")
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
            .navigationTitle("Portfolio Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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


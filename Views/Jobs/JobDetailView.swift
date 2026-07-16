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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(job.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        StatusBadge(status: liveJob.status)
                    }

                    if let category = job.category {
                        Label(category.rawValue, systemImage: "tag.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                Divider()

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.localized("description"))
                        .font(.headline)

                    Text(job.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Photos
                if let photoURLs = job.photoURLs, !photoURLs.isEmpty {
                    PhotoGalleryView(
                        photoURLs: photoURLs,
                        title: "Job Requirements"
                    )
                }

                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.localized("location"))
                        .font(.headline)

                    Label(job.location, systemImage: "mappin.circle.fill")
                        .font(.body)
                        .foregroundColor(.secondary)

                    // Map Preview
                    if let coordinate = job.coordinate {
                        Map(position: .constant(.region(MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )))) {
                            Marker(job.title, coordinate: coordinate)
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                // Budget
                if let budget = job.budget {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("budget"))
                            .font(.headline)

                        Text(Money.string(budget))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal)
                }

                // Date Posted
                VStack(alignment: .leading, spacing: 8) {
                    Text("Posted")
                        .font(.headline)

                    Text(job.datePosted, style: .date)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Job Status Management (for job poster)
                if authViewModel.isJobPoster && authViewModel.currentUser?.uid == job.createdBy {
                    Divider()
                        .padding(.vertical)

                    // Job Status Actions
                    if liveJob.status == .open {
                        // Check if there's an accepted offer
                        if let accepted = acceptedOffer {
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                        Text("Offer Accepted")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }

                                    let displayPrice = accepted.finalPrice ?? accepted.counterPrice ?? accepted.price
                                    HStack {
                                        Text("Accepted Price:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("₪\(String(format: "%.0f", displayPrice))")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }

                                    Text("By: \(accepted.contractorName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)

                                Button(action: { showMarkInProgressConfirmation = true }) {
                                    HStack {
                                        Image(systemName: "hammer.fill")
                                        Text("Mark Job as In Progress")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                    } else if liveJob.status == .inProgress {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.orange)
                                    Text("Job In Progress")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }

                                Text("The job is currently being worked on. Mark as done when the work is completed.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)

                            Button(action: { showMarkDoneConfirmation = true }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark Job as Done")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    } else if liveJob.status == .completed {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text("Job Completed")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }

                                Text("This job has been marked as completed.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding()
                    }

                    Divider()
                        .padding(.vertical)

                    // Offers Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Offers (\(offers.count))")
                            .font(.headline)
                            .padding(.horizontal)

                        if isLoadingOffers {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if offers.isEmpty {
                            EmptyStateView(
                                icon: "doc.text",
                                title: "No offers yet",
                                subtitle: "Wait for contractors to submit offers"
                            )
                        } else {
                            ForEach(offers) { offer in
                                NavigationLink(destination: OfferDetailView(offer: offer, jobId: job.id ?? "")) {
                                    OfferCardView(offer: offer)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }

                // Submit Offer Button (for contractors)
                if authViewModel.isContractor && liveJob.status == .open {
                    Button(action: { showOfferForm = true }) {
                        Text(localization.localized("submitOffer"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Delete button for job owner
            if authViewModel.isJobPoster && authViewModel.currentUser?.uid == job.createdBy {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isDeleting)
                }
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
        .alert(L10n.Common.error.string, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
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

    private func startOffersListener() {
        guard offersListener == nil, let jobId = job.id else { return }
        guard authViewModel.isJobPoster && authViewModel.currentUser?.uid == job.createdBy else { return }

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

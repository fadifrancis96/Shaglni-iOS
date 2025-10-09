//
//  JobDetailView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI
import MapKit

struct JobDetailView: View {
    let job: Job
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var showOfferForm = false
    @State private var offers: [Offer] = []
    @State private var isLoadingOffers = false
    
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
                        
                        StatusBadge(status: job.status)
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
                        
                        Text("$\(Int(budget))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
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
                
                // Offers Section (for job poster)
                if authViewModel.isJobPoster && authViewModel.currentUser?.uid == job.createdBy {
                    Divider()
                        .padding(.vertical)
                    
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
                if authViewModel.isContractor && job.status == .open {
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
        .sheet(isPresented: $showOfferForm) {
            OfferFormView(job: job)
        }
        .onAppear(perform: loadOffers)
    }
    
    private func loadOffers() {
        guard let jobId = job.id else { return }
        guard authViewModel.isJobPoster && authViewModel.currentUser?.uid == job.createdBy else { return }
        
        isLoadingOffers = true
        FirestoreService.shared.fetchOffersForJob(jobId: jobId) { result in
            isLoadingOffers = false
            switch result {
            case .success(let fetchedOffers):
                offers = fetchedOffers
            case .failure(let error):
                print("Error loading offers: \(error.localizedDescription)")
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

//
//  OfferDetailView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct OfferDetailView: View {
    let offer: Offer
    let jobId: String
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showAcceptConfirmation = false
    @State private var showRejectConfirmation = false
    @State private var showNegotiation = false
    @State private var showContractorProfile = false
    @State private var contractorProfile: ContractorProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Negotiation fields
    @State private var counterPrice = ""
    @State private var negotiationMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Status Badge
                    HStack {
                        Spacer()
                        statusBadge
                        Spacer()
                    }
                    .padding(.top)
                    
                    // Offer Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Offer Details")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        // Price
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Offered Price")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("₪\(String(format: "%.0f", offer.price))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            if let counterPrice = offer.counterPrice {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Counter Offer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("₪\(String(format: "%.0f", counterPrice))")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Message
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(offer.message)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        if let negotiationMsg = offer.negotiationMessage {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Negotiation Note", systemImage: "text.bubble.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                Text(negotiationMsg)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        // Dates
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.secondary)
                                Text("Submitted: \(offer.createdAt, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let respondedAt = offer.respondedAt {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Responded: \(respondedAt, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Contractor Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contractor")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Button(action: { loadContractorProfile() }) {
                            HStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.blue)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(offer.contractorName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let profile = contractorProfile {
                                        HStack(spacing: 4) {
                                            if let rating = profile.rating {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                                    .font(.caption)
                                                Text(String(format: "%.1f", rating))
                                                    .font(.caption)
                                            }
                                            Text("• \(profile.completedJobsCount) jobs")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    } else {
                                        Text("Tap to view profile")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Action Buttons (Only for job poster and pending offers)
                    if authViewModel.isJobPoster && offer.status == .pending {
                        VStack(spacing: 12) {
                            // Accept Button
                            Button(action: { showAcceptConfirmation = true }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Accept Offer")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            // Negotiate Button
                            Button(action: { showNegotiation = true }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Negotiate Price")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            // Reject Button
                            Button(action: { showRejectConfirmation = true }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Decline Offer")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showContractorProfile) {
                if let profile = contractorProfile {
                    ContractorProfileView(contractor: profile)
                }
            }
            .sheet(isPresented: $showNegotiation) {
                negotiationSheet
            }
            .alert("Accept Offer", isPresented: $showAcceptConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Accept") {
                    acceptOffer()
                }
            } message: {
                Text("Accept this offer for ₪\(String(format: "%.0f", offer.price))?")
            }
            .alert("Decline Offer", isPresented: $showRejectConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Decline", role: .destructive) {
                    rejectOffer()
                }
            } message: {
                Text("Are you sure you want to decline this offer?")
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    private var statusBadge: some View {
        HStack {
            Image(systemName: statusIcon)
            Text(statusText)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(statusColor)
        .cornerRadius(20)
    }
    
    private var statusColor: Color {
        switch offer.status {
        case .pending: return .orange
        case .accepted: return .green
        case .rejected: return .red
        case .counterOffer: return .blue
        }
    }
    
    private var statusText: String {
        switch offer.status {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .rejected: return "Declined"
        case .counterOffer: return "Counter Offer"
        }
    }
    
    private var statusIcon: String {
        switch offer.status {
        case .pending: return "clock.fill"
        case .accepted: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .counterOffer: return "arrow.triangle.2.circlepath"
        }
    }
    
    private var negotiationSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Counter Offer")) {
                    TextField("Your Price", text: $counterPrice)
                        .keyboardType(.decimalPad)
                    
                    TextEditor(text: $negotiationMessage)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if negotiationMessage.isEmpty {
                                    Text("Explain your counter offer...")
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                Section {
                    Text("Original Price: ₪\(String(format: "%.0f", offer.price))")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Negotiate Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showNegotiation = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendCounterOffer()
                    }
                    .disabled(counterPrice.isEmpty || negotiationMessage.isEmpty)
                }
            }
        }
    }
    
    private func loadContractorProfile() {
        FirestoreService.shared.fetchContractorProfile(userId: offer.contractorId) { result in
            switch result {
            case .success(let profile):
                contractorProfile = profile
                showContractorProfile = true
            case .failure(let error):
                errorMessage = "Could not load contractor profile: \(error.localizedDescription)"
            }
        }
    }
    
    private func acceptOffer() {
        guard let offerId = offer.id else { return }
        
        isLoading = true
        FirestoreService.shared.updateOfferStatus(jobId: jobId, offerId: offerId, status: .accepted) { result in
            isLoading = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func rejectOffer() {
        guard let offerId = offer.id else { return }
        
        isLoading = true
        FirestoreService.shared.updateOfferStatus(jobId: jobId, offerId: offerId, status: .rejected) { result in
            isLoading = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func sendCounterOffer() {
        guard let offerId = offer.id,
              let price = Double(counterPrice) else { return }
        
        isLoading = true
        showNegotiation = false
        
        FirestoreService.shared.sendCounterOffer(
            jobId: jobId,
            offerId: offerId,
            counterPrice: price,
            message: negotiationMessage
        ) { result in
            isLoading = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    OfferDetailView(
        offer: Offer(
            id: "1",
            jobId: "job1",
            contractorId: "contractor1",
            contractorName: "Ahmed Al-Rashid",
            message: "I can complete this job within 2 days. I have 10 years of experience in plumbing.",
            price: 500,
            status: .pending,
            createdAt: Date()
        ),
        jobId: "job1"
    )
    .environmentObject(AuthViewModel())
}


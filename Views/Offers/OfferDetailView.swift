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
    @State private var jobStatus: JobStatus = .open
    
    // Counter offer response
    @State private var showAcceptCounterConfirmation = false
    @State private var showDeclineCounterConfirmation = false
    
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
                    
                    // Job Status Warning
                    if jobStatus != .open && (offer.status == .pending || offer.status == .counterOffer) {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Job Status: \(jobStatus == .inProgress ? "In Progress" : "Completed")")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            
                            Text("This job is no longer accepting offer actions. Manage the job status from the job detail page.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding()
                    }
                    
                    // Action Buttons (only show if job is still open)
                    if authViewModel.isJobPoster && offer.status == .pending && jobStatus == .open {
                        // Job Poster Actions for Pending Offers
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
                    } else if !authViewModel.isJobPoster && offer.status == .counterOffer && jobStatus == .open {
                        // Contractor Actions for Counter Offers
                        VStack(spacing: 12) {
                            // Counter Offer Info
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Counter Offer Received")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                
                                if let counterPrice = offer.counterPrice {
                                    HStack {
                                        Text("Job Poster's Price:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("₪\(String(format: "%.0f", counterPrice))")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                if let negotiationMsg = offer.negotiationMessage {
                                    Text(negotiationMsg)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Accept Counter Offer Button
                            Button(action: { showAcceptCounterConfirmation = true }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Accept Counter Offer")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            // Decline Counter Offer Button
                            Button(action: { showDeclineCounterConfirmation = true }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Decline Counter Offer")
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
                    } else if authViewModel.isJobPoster && offer.status == .counterOffer && offer.contractorAcceptedCounter == true && jobStatus == .open {
                        // Job Poster Final Approval (contractor accepted counter offer)
                        VStack(spacing: 12) {
                            // Waiting info
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Contractor Accepted Your Counter Offer!")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                
                                if let counterPrice = offer.counterPrice {
                                    HStack {
                                        Text("Agreed Price:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("₪\(String(format: "%.0f", counterPrice))")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.top, 4)
                                }
                                
                                Text("Accept this offer to finalize the agreement. You can manage the job status from the job detail page.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Accept Button (to finalize the counter offer)
                            Button(action: { showAcceptConfirmation = true }) {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                    Text("Accept & Finalize Offer")
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
                    } else if authViewModel.isJobPoster && offer.status == .accepted {
                        // Job Poster - Offer Accepted
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
                                
                                let displayPrice = offer.finalPrice ?? offer.counterPrice ?? offer.price
                                HStack {
                                    Text("Final Price:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("₪\(String(format: "%.0f", displayPrice))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                
                                Text("Manage job status from the job detail page.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
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
            .alert("Decline Offer", isPresented: $showRejectConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Decline", role: .destructive) {
                    rejectOffer()
                }
            } message: {
                Text("Are you sure you want to decline this offer?")
            }
            .alert("Accept Counter Offer", isPresented: $showAcceptCounterConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Accept") {
                    acceptCounterOffer()
                }
            } message: {
                if let counterPrice = offer.counterPrice {
                    Text("Accept the job poster's counter offer of ₪\(String(format: "%.0f", counterPrice))?")
                } else {
                    Text("Accept this counter offer?")
                }
            }
            .alert("Decline Counter Offer", isPresented: $showDeclineCounterConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Decline", role: .destructive) {
                    declineCounterOffer()
                }
            } message: {
                Text("Are you sure you want to decline this counter offer? This will remove your offer completely.")
            }
            .alert("Accept Offer", isPresented: $showAcceptConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Accept") {
                    // If it's a counter offer that contractor accepted, finalize it
                    if offer.status == .counterOffer && offer.contractorAcceptedCounter == true {
                        finalizeCounterOffer()
                    } else {
                        acceptOffer()
                    }
                }
            } message: {
                if offer.status == .counterOffer && offer.contractorAcceptedCounter == true {
                    if let counterPrice = offer.counterPrice {
                        Text("Finalize this offer for ₪\(String(format: "%.0f", counterPrice))? All other offers will be automatically rejected.")
                    } else {
                        Text("Finalize this offer? All other offers will be automatically rejected.")
                    }
                } else {
                    Text("Accept this offer for ₪\(String(format: "%.0f", offer.price))? All other offers for this job will be automatically rejected.")
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .onAppear {
                loadJobStatus()
            }
        }
    }
    
    private func loadJobStatus() {
        FirestoreService.shared.fetchJob(jobId: jobId) { result in
            switch result {
            case .success(let job):
                jobStatus = job.status
            case .failure(let error):
                print("Error loading job status: \(error.localizedDescription)")
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
        Task {
            do {
                try await OffersRepository.shared.acceptOfferAndCloseOthers(
                    jobId: jobId,
                    acceptedOfferId: offerId,
                    finalPrice: offer.price,
                    contractorId: offer.contractorId
                )
                await openChatThread(finalPrice: offer.price)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Create-or-update the chat thread for this job so both sides can message immediately
    /// after acceptance. Best-effort — failures are logged but don't block dismissal.
    private func openChatThread(finalPrice: Double) async {
        guard let posterId = authViewModel.currentUser?.uid,
              let posterName = authViewModel.currentUserData?.displayName else { return }
        do {
            let job = try await JobsRepository.shared.fetch(jobId: jobId)
            try await ChatRepository.shared.ensureThread(
                jobId: jobId,
                jobTitle: job.title,
                jobPosterId: posterId,
                jobPosterName: posterName,
                contractorId: offer.contractorId,
                contractorName: offer.contractorName
            )
        } catch {
            AppLogger.chat.warning("Failed to seed chat thread: \(error.localizedDescription, privacy: .public)")
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
    
    private func acceptCounterOffer() {
        guard let offerId = offer.id else { return }
        
        isLoading = true
        FirestoreService.shared.respondToCounterOffer(jobId: jobId, offerId: offerId, accept: true, counterPrice: offer.counterPrice) { result in
            isLoading = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func declineCounterOffer() {
        guard let offerId = offer.id else { return }
        
        isLoading = true
        FirestoreService.shared.respondToCounterOffer(jobId: jobId, offerId: offerId, accept: false, counterPrice: nil) { result in
            isLoading = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func finalizeCounterOffer() {
        guard let offerId = offer.id else { return }
        let finalPrice = offer.counterPrice ?? offer.price
        isLoading = true
        Task {
            do {
                try await OffersRepository.shared.acceptOfferAndCloseOthers(
                    jobId: jobId,
                    acceptedOfferId: offerId,
                    finalPrice: finalPrice,
                    contractorId: offer.contractorId
                )
                await openChatThread(finalPrice: finalPrice)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
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


//
//  OfferFormView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct OfferFormView: View {
    let job: Job
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var price = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Job")) {
                    Text(job.title)
                        .font(.headline)
                    
                    Text(job.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Section(header: Text("Your Offer")) {
                    TextField(localization.localized("price"), text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if message.isEmpty {
                                    Text(localization.localized("message"))
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(localization.localized("submitOffer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localization.localized("cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleSubmit) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(localization.localized("submit"))
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !price.isEmpty && !message.isEmpty && Double(price) != nil
    }
    
    private func handleSubmit() {
        guard let userId = authViewModel.currentUser?.uid,
              let userName = authViewModel.currentUserData?.displayName,
              let jobId = job.id,
              let priceValue = Double(price) else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        let offer = Offer(
            jobId: jobId,
            contractorId: userId,
            contractorName: userName,
            message: message,
            price: priceValue,
            status: .pending,
            createdAt: Date()
        )
        
        FirestoreService.shared.submitOffer(offer, jobId: jobId) { result in
            isSubmitting = false
            
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
    OfferFormView(job: Job(
        id: "1",
        title: "Fix Kitchen Plumbing",
        description: "Need a plumber to fix leaking pipes",
        location: "Riyadh",
        datePosted: Date(),
        createdBy: "user123",
        status: .open
    ))
    .environmentObject(AuthViewModel())
    .environmentObject(LocalizationManager())
}

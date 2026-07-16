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
    @EnvironmentObject var offersRepo: OffersRepository
    @Environment(\.dismiss) var dismiss
    
    @State private var price = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L10n(key: "offerForm.job").string)) {
                    Text(job.title)
                        .font(.headline)
                    
                    Text(job.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Section(header: Text(L10n(key: "offerForm.yourOffer").string)) {
                    TextField(L10n.Field.price.string, text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if message.isEmpty {
                                    Text(L10n.Field.message.string)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 4)
                                        .padding(.top, 8)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
            }
            .navigationTitle(L10n.Action.submitOffer.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.Common.cancel.string) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleSubmit) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(L10n.Common.submit.string)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .alert(L10n.Common.error.string, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button(L10n(key: "common.ok").string, role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var isFormValid: Bool {
        !price.isEmpty && !message.isEmpty && (Double(price) ?? 0) > 0
    }

    private func handleSubmit() {
        guard let userId = authViewModel.currentUser?.uid,
              let userName = authViewModel.currentUserData?.displayName,
              let jobId = job.id else { return }

        guard let priceValue = Double(price), priceValue > 0 else {
            errorMessage = AppError.validation("Price must be greater than zero").errorDescription
            return
        }

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

        Task {
            do {
                try await offersRepo.submit(offer, jobId: jobId)
                isSubmitting = false
                dismiss()
            } catch {
                isSubmitting = false
                errorMessage = AppError(error).errorDescription
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
    .environmentObject(LocalizationManager.shared)
    .environmentObject(OffersRepository.shared)
}

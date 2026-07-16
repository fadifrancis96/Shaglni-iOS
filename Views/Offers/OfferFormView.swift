//
//  OfferFormView.swift
//  Shaglni
//
//  Contractor's offer submission sheet: job summary, price and message
//  inputs, and a single prominent submit action.
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
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        jobCard

                        VStack(spacing: DS.Space.l) {
                            DSTextField(
                                label: L10n.Field.price.string,
                                systemImage: "banknote",
                                text: $price,
                                placeholder: L10n.Field.price.string,
                                keyboard: .decimalPad
                            )

                            DSTextEditor(
                                label: L10n.Field.message.string,
                                text: $message,
                                placeholder: L10n.Field.message.string
                            )
                        }

                        if let errorMessage = errorMessage {
                            DSBanner(kind: .error, message: errorMessage)
                        }

                        Button(action: handleSubmit) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(Color.onBrand)
                            } else {
                                Text(L10n.Common.submit.string)
                            }
                        }
                        .buttonStyle(DSPrimaryButtonStyle())
                        .disabled(!isFormValid || isSubmitting)
                        .opacity(!isFormValid || isSubmitting ? 0.5 : 1)
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, DS.Space.l)
                    .padding(.bottom, DS.Space.xxl)
                }
            }
            .navigationTitle(L10n.Action.submitOffer.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.Common.cancel.string) {
                        dismiss()
                    }
                    .foregroundStyle(Color.inkMuted)
                }
            }
        }
    }

    // MARK: - Job summary

    private var jobCard: some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            if let category = job.category {
                DSCategoryIcon(category: category)
            }

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(job.title)
                    .font(.dsHeadline)
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(job.description)
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                if let budget = job.budget {
                    HStack(spacing: DS.Space.xs) {
                        Text(L10n.Field.budget.string)
                            .font(.dsCaption)
                            .foregroundStyle(Color.inkFaint)
                        DSPriceText(amount: budget)
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
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

//
//  OfferDetailView.swift
//  Shaglni
//
//  The negotiation hub: contractor identity, current effective price,
//  the offer → counter → response timeline, and role-gated actions.
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
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        contractorCard

                        priceCard

                        timelineCard

                        messageCard

                        if let errorMessage = errorMessage {
                            DSBanner(kind: .error, message: errorMessage)
                        }

                        if jobStatus != .open && (offer.status == .pending || offer.status == .counterOffer) {
                            jobClosedBanner
                        }

                        actionSection
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, DS.Space.l)
                    .padding(.bottom, DS.Space.xxl)
                }
            }
            .navigationTitle("Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.done.string) {
                        dismiss()
                    }
                    .font(.dsCaptionBold)
                    .foregroundStyle(Color.brand)
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
            .alert(L10n.Action.declineOffer.string, isPresented: $showRejectConfirmation) {
                Button(L10n.Common.cancel.string, role: .cancel) { }
                Button("Decline", role: .destructive) {
                    rejectOffer()
                }
            } message: {
                Text("Are you sure you want to decline this offer?")
            }
            .alert("Accept Counter Offer", isPresented: $showAcceptCounterConfirmation) {
                Button(L10n.Common.cancel.string, role: .cancel) { }
                Button("Accept") {
                    acceptCounterOffer()
                }
            } message: {
                if let counterPrice = offer.counterPrice {
                    Text("Accept the job poster's counter offer of \(Money.string(counterPrice))?")
                } else {
                    Text("Accept this counter offer?")
                }
            }
            .alert("Decline Counter Offer", isPresented: $showDeclineCounterConfirmation) {
                Button(L10n.Common.cancel.string, role: .cancel) { }
                Button("Decline", role: .destructive) {
                    declineCounterOffer()
                }
            } message: {
                Text("Are you sure you want to decline this counter offer? This will remove your offer completely.")
            }
            .alert(L10n.Action.acceptOffer.string, isPresented: $showAcceptConfirmation) {
                Button(L10n.Common.cancel.string, role: .cancel) { }
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
                        Text("Finalize this offer for \(Money.string(counterPrice))? All other offers will be automatically rejected.")
                    } else {
                        Text("Finalize this offer? All other offers will be automatically rejected.")
                    }
                } else {
                    Text("Accept this offer for \(Money.string(offer.price))? All other offers for this job will be automatically rejected.")
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.brand)
                }
            }
            .onAppear {
                loadJobStatus()
            }
        }
    }

    // MARK: - Contractor identity

    private var contractorCard: some View {
        Button(action: { loadContractorProfile() }) {
            HStack(spacing: DS.Space.m) {
                DSAvatar(
                    name: offer.contractorName,
                    urlString: contractorProfile?.profilePicture,
                    size: 52
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.contractorName)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)

                    if let profile = contractorProfile {
                        HStack(spacing: DS.Space.s) {
                            if let rating = profile.rating {
                                DSRatingStars(rating: rating)
                            }
                            Text("• \(profile.completedJobsCount) jobs")
                                .font(.dsCaption)
                                .foregroundStyle(Color.inkMuted)
                        }
                    } else {
                        Text("Tap to view profile")
                            .font(.dsCaption)
                            .foregroundStyle(Color.brand)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.inkFaint)
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard()
        }
        .buttonStyle(DSPressableStyle())
    }

    // MARK: - Price

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(priceLabel)
                    .font(.dsMicro)
                    .foregroundStyle(Color.inkMuted)
                    .textCase(.uppercase)
                    .kerning(0.6)

                Spacer()

                DSStatusPill(status: offer.status)
            }

            DSPriceText(amount: offer.displayPrice, font: .dsPriceLarge, tint: priceTint)

            if offer.counterPrice != nil {
                HStack(spacing: DS.Space.s) {
                    Text(Money.string(offer.price))
                        .font(.dsSub)
                        .strikethrough()
                        .foregroundStyle(Color.inkFaint)
                    Text("Offered Price")
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkFaint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    private var priceLabel: String {
        switch offer.negotiationState {
        case .pending, .rejected:
            return "Offered Price"
        case .countered:
            return L10n.OfferUI.posterCounter.string
        case .contractorAcceptedCounter, .accepted:
            return "Final Price"
        }
    }

    private var priceTint: Color {
        switch offer.negotiationState {
        case .pending:                              return .brand
        case .countered:                            return .warning
        case .contractorAcceptedCounter, .accepted: return .success
        case .rejected:                             return .inkFaint
        }
    }

    // MARK: - Negotiation timeline

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimelineStep(
                icon: "paperplane.fill",
                tint: .brand,
                background: .brandSoft,
                title: "Submitted",
                detail: Money.string(offer.price),
                date: offer.createdAt,
                isLast: !hasCounterStep && !hasResponseStep
            )

            if hasCounterStep, let counter = offer.counterPrice {
                TimelineStep(
                    icon: "arrow.triangle.2.circlepath",
                    tint: .warning,
                    background: .warningSoft,
                    title: L10n.OfferUI.posterCounter.string,
                    detail: Money.string(counter),
                    isLast: !hasResponseStep
                )
            }

            if hasResponseStep {
                responseStep
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    private var hasCounterStep: Bool { offer.counterPrice != nil }

    private var hasResponseStep: Bool {
        switch offer.negotiationState {
        case .pending: return false
        default:       return true
        }
    }

    @ViewBuilder
    private var responseStep: some View {
        switch offer.negotiationState {
        case .accepted(let finalPrice):
            TimelineStep(
                icon: "checkmark.seal.fill",
                tint: .success,
                background: .successSoft,
                title: OfferStatus.accepted.localized,
                detail: Money.string(finalPrice),
                date: offer.respondedAt,
                isLast: true
            )
        case .rejected:
            TimelineStep(
                icon: "xmark.circle.fill",
                tint: .danger,
                background: .dangerSoft,
                title: OfferStatus.rejected.localized,
                date: offer.respondedAt,
                isLast: true
            )
        case .contractorAcceptedCounter(let finalPrice):
            TimelineStep(
                icon: "checkmark.circle.fill",
                tint: .success,
                background: .successSoft,
                title: "Contractor accepted your counter offer",
                detail: Money.string(finalPrice),
                isLast: true
            )
        case .countered:
            TimelineStep(
                icon: "clock.fill",
                tint: .warning,
                background: .warningSoft,
                title: authViewModel.isJobPoster
                    ? "Waiting for contractor response"
                    : L10n.OfferUI.counterReceived.string,
                isLast: true
            )
        case .pending:
            EmptyView()
        }
    }

    // MARK: - Message

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            Text(L10n.Field.message.string)
                .font(.dsCaptionBold)
                .foregroundStyle(Color.inkMuted)

            Text(offer.message)
                .font(.dsBody)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.leading)

            if let negotiationMsg = offer.negotiationMessage {
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    Label("Negotiation Note", systemImage: "text.bubble.fill")
                        .font(.dsCaptionBold)
                        .foregroundStyle(Color.warning)
                    Text(negotiationMsg)
                        .font(.dsSub)
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsInset()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
    }

    // MARK: - Job closed notice

    private var jobClosedBanner: some View {
        DSBanner(
            kind: .info,
            message: "Job Status: \(jobStatus.localized). This job is no longer accepting offer actions. Manage the job status from the job detail page."
        )
    }

    // MARK: - Role-gated actions

    @ViewBuilder
    private var actionSection: some View {
        if authViewModel.isJobPoster && offer.status == .pending && jobStatus == .open {
            // Job Poster Actions for Pending Offers
            VStack(spacing: DS.Space.m) {
                Button(action: { showAcceptConfirmation = true }) {
                    Label(L10n.Action.acceptOffer.string, systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(DSPrimaryButtonStyle())

                Button(action: { showNegotiation = true }) {
                    Label(L10n.Action.negotiate.string, systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(DSTonalButtonStyle(tint: .warning, background: .warningSoft))

                Button(action: { showRejectConfirmation = true }) {
                    Label(L10n.Action.declineOffer.string, systemImage: "xmark.circle.fill")
                }
                .buttonStyle(DSTonalButtonStyle(tint: .danger, background: .dangerSoft))
            }
        } else if !authViewModel.isJobPoster && offer.status == .counterOffer && jobStatus == .open {
            // Contractor Actions for Counter Offers
            VStack(spacing: DS.Space.m) {
                DSBanner(kind: .info, message: L10n.OfferUI.counterReceived.string)

                Button(action: { showAcceptCounterConfirmation = true }) {
                    Label("Accept Counter Offer", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(DSPrimaryButtonStyle())

                Button(action: { showDeclineCounterConfirmation = true }) {
                    Label("Decline Counter Offer", systemImage: "xmark.circle.fill")
                }
                .buttonStyle(DSTonalButtonStyle(tint: .danger, background: .dangerSoft))
            }
        } else if authViewModel.isJobPoster && offer.status == .counterOffer && offer.contractorAcceptedCounter == true && jobStatus == .open {
            // Job Poster Final Approval (contractor accepted counter offer)
            VStack(spacing: DS.Space.m) {
                DSBanner(kind: .success, message: "Contractor Accepted Your Counter Offer!")

                Text("Accept this offer to finalize the agreement. You can manage the job status from the job detail page.")
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: { showAcceptConfirmation = true }) {
                    Label("Accept & Finalize Offer", systemImage: "checkmark.seal.fill")
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }
        } else if authViewModel.isJobPoster && offer.status == .accepted {
            // Job Poster - Offer Accepted
            VStack(spacing: DS.Space.m) {
                DSBanner(kind: .success, message: "Offer Accepted")

                Text("Manage job status from the job detail page.")
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Negotiation sheet

    private var negotiationSheet: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        VStack(spacing: DS.Space.l) {
                            DSTextField(
                                label: "Your Price",
                                systemImage: "banknote",
                                text: $counterPrice,
                                placeholder: L10n.Field.price.string,
                                keyboard: .decimalPad
                            )

                            DSTextEditor(
                                label: L10n.Field.message.string,
                                text: $negotiationMessage,
                                placeholder: "Explain your counter offer..."
                            )
                        }

                        HStack {
                            Text("Original Price:")
                                .font(.dsSub)
                                .foregroundStyle(Color.inkMuted)
                            Spacer()
                            DSPriceText(amount: offer.price, tint: .inkMuted)
                        }
                        .dsInset()
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, DS.Space.l)
                    .padding(.bottom, DS.Space.xxl)
                }
            }
            .navigationTitle(L10n.Action.negotiate.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.Common.cancel.string) {
                        showNegotiation = false
                    }
                    .foregroundStyle(Color.inkMuted)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendCounterOffer()
                    }
                    .font(.dsCaptionBold)
                    .foregroundStyle(Color.brand)
                    .disabled(counterPrice.isEmpty || negotiationMessage.isEmpty)
                }
            }
        }
    }

    // MARK: - Data

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

// MARK: - Timeline step

/// One row of the negotiation timeline: tinted icon bubble, connector line,
/// title, optional price detail and date.
private struct TimelineStep: View {
    let icon: String
    let tint: Color
    let background: Color
    let title: String
    var detail: String? = nil
    var date: Date? = nil
    var isLast = false

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(Circle().fill(background))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.dsCaptionBold)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.leading)

                if let detail {
                    Text(detail)
                        .font(.dsPrice)
                        .foregroundStyle(tint)
                }

                if let date {
                    Text(date, style: .date)
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkFaint)
                }
            }
            .padding(.top, DS.Space.xs)
            .padding(.bottom, isLast ? 0 : DS.Space.l)

            Spacer(minLength: 0)
        }
        .background(alignment: .topLeading) {
            // Connector line from this step's icon down to the next step.
            if !isLast {
                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 2)
                    .padding(.top, 36)
                    .padding(.leading, 15)
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

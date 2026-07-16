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
    @EnvironmentObject var jobsRepo: JobsRepository
    @EnvironmentObject var offersRepo: OffersRepository
    @EnvironmentObject var contractorsRepo: ContractorsRepository
    @EnvironmentObject var chatRepo: ChatRepository
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
            .navigationTitle(L10n(key: "offerDetail.navTitle").string)
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
                Button(L10n(key: "offerDetail.decline").string, role: .destructive) {
                    rejectOffer()
                }
            } message: {
                Text(L10n(key: "offerDetail.confirmDecline").string)
            }
            .alert(L10n(key: "offerDetail.acceptCounter").string, isPresented: $showAcceptCounterConfirmation) {
                Button(L10n.Common.cancel.string, role: .cancel) { }
                Button(L10n(key: "offerDetail.accept").string) {
                    acceptCounterOffer()
                }
            } message: {
                if let counterPrice = offer.counterPrice {
                    Text(L10n(key: "offerDetail.confirmAcceptCounterPrice").format(Money.string(counterPrice)))
                } else {
                    Text(L10n(key: "offerDetail.confirmAcceptCounter").string)
                }
            }
            .alert(L10n(key: "offerDetail.declineCounter").string, isPresented: $showDeclineCounterConfirmation) {
                Button(L10n.Common.cancel.string, role: .cancel) { }
                Button(L10n(key: "offerDetail.decline").string, role: .destructive) {
                    declineCounterOffer()
                }
            } message: {
                Text(L10n(key: "offerDetail.confirmDeclineCounter").string)
            }
            .alert(L10n.Action.acceptOffer.string, isPresented: $showAcceptConfirmation) {
                Button(L10n.Common.cancel.string, role: .cancel) { }
                Button(L10n(key: "offerDetail.accept").string) {
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
                        Text(L10n(key: "offerDetail.confirmFinalizePrice").format(Money.string(counterPrice)))
                    } else {
                        Text(L10n(key: "offerDetail.confirmFinalize").string)
                    }
                } else {
                    Text(L10n(key: "offerDetail.confirmAcceptPrice").format(Money.string(offer.price)))
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
            .task {
                await loadJobStatus()
                await loadContractorProfile(presentSheet: false)
            }
        }
    }

    // MARK: - Contractor identity

    private var contractorCard: some View {
        Button(action: { Task { await loadContractorProfile() } }) {
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
                            Text(L10n(key: "offerDetail.jobsCount").format(profile.completedJobsCount))
                                .font(.dsCaption)
                                .foregroundStyle(Color.inkMuted)
                        }
                    } else {
                        Text(L10n(key: "offerDetail.tapToViewProfile").string)
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
                    Text(L10n(key: "offerDetail.offeredPrice").string)
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
            return L10n(key: "offerDetail.offeredPrice").string
        case .countered:
            return L10n.OfferUI.posterCounter.string
        case .contractorAcceptedCounter, .accepted:
            return L10n(key: "offerDetail.finalPriceLabel").string
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
                title: L10n(key: "offerDetail.timelineSubmitted").string,
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
                title: L10n(key: "receivedOffers.contractorAcceptedCounter").string,
                detail: Money.string(finalPrice),
                isLast: true
            )
        case .countered:
            TimelineStep(
                icon: "clock.fill",
                tint: .warning,
                background: .warningSoft,
                title: authViewModel.isJobPoster
                    ? L10n(key: "receivedOffers.waitingForContractor").string
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
                    Label(L10n(key: "offerDetail.negotiationNote").string, systemImage: "text.bubble.fill")
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
            message: "\(L10n(key: "offerDetail.jobStatus").format(jobStatus.localized)). \(L10n(key: "offerDetail.jobClosedNote").string)"
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
                    Label(L10n(key: "offerDetail.acceptCounter").string, systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(DSPrimaryButtonStyle())

                Button(action: { showDeclineCounterConfirmation = true }) {
                    Label(L10n(key: "offerDetail.declineCounter").string, systemImage: "xmark.circle.fill")
                }
                .buttonStyle(DSTonalButtonStyle(tint: .danger, background: .dangerSoft))
            }
        } else if authViewModel.isJobPoster && offer.status == .counterOffer && offer.contractorAcceptedCounter == true && jobStatus == .open {
            // Job Poster Final Approval (contractor accepted counter offer)
            VStack(spacing: DS.Space.m) {
                DSBanner(kind: .success, message: L10n(key: "offerDetail.contractorAcceptedCounter").string)

                Text(L10n(key: "offerDetail.finalizeNote").string)
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: { showAcceptConfirmation = true }) {
                    Label(L10n(key: "offerDetail.acceptFinalize").string, systemImage: "checkmark.seal.fill")
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }
        } else if authViewModel.isJobPoster && offer.status == .accepted {
            // Job Poster - Offer Accepted
            VStack(spacing: DS.Space.m) {
                DSBanner(kind: .success, message: L10n(key: "offerDetail.offerAccepted").string)

                Text(L10n(key: "offerDetail.manageJobNote").string)
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
                                label: L10n(key: "offerDetail.yourPrice").string,
                                systemImage: "banknote",
                                text: $counterPrice,
                                placeholder: L10n.Field.price.string,
                                keyboard: .decimalPad
                            )

                            DSTextEditor(
                                label: L10n.Field.message.string,
                                text: $negotiationMessage,
                                placeholder: L10n(key: "offerDetail.explainCounter").string
                            )
                        }

                        HStack {
                            Text(L10n(key: "offerDetail.originalPriceLabel").string)
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
                    Button(L10n(key: "common.send").string) {
                        sendCounterOffer()
                    }
                    .font(.dsCaptionBold)
                    .foregroundStyle(Color.brand)
                    .disabled(counterPrice.isEmpty || negotiationMessage.isEmpty)
                }
            }
            .alert(L10n.Common.error.string, isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button(L10n(key: "common.ok").string, role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Data

    private func loadJobStatus() async {
        do {
            let job = try await jobsRepo.fetch(jobId: jobId)
            jobStatus = job.status
        } catch {
            errorMessage = AppError(error).errorDescription
        }
    }

    /// Fetch the contractor's public profile. When `presentSheet` is false (initial
    /// prefetch for the identity card) failures stay silent; on explicit taps the
    /// error is surfaced and the profile sheet opens on success.
    private func loadContractorProfile(presentSheet: Bool = true) async {
        do {
            contractorProfile = try await contractorsRepo.fetchProfile(userId: offer.contractorId)
            if presentSheet {
                showContractorProfile = true
            }
        } catch {
            if presentSheet {
                errorMessage = AppError(error).errorDescription
            }
        }
    }

    private func acceptOffer() {
        guard let offerId = offer.id else { return }
        isLoading = true
        Task {
            do {
                try await offersRepo.acceptOfferAndCloseOthers(
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
                errorMessage = AppError(error).errorDescription
            }
        }
    }

    /// Create-or-update the chat thread for this job so both sides can message immediately
    /// after acceptance. Best-effort — failures are logged but don't block dismissal.
    private func openChatThread(finalPrice: Double) async {
        guard let posterId = authViewModel.currentUser?.uid,
              let posterName = authViewModel.currentUserData?.displayName else { return }
        do {
            let job = try await jobsRepo.fetch(jobId: jobId)
            try await chatRepo.ensureThread(
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
        Task {
            do {
                try await offersRepo.updateStatus(jobId: jobId, offerId: offerId, status: .rejected)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = AppError(error).errorDescription
            }
        }
    }

    private func sendCounterOffer() {
        guard let offerId = offer.id else { return }

        // Validate the price BEFORE dismissing the sheet so a bad value surfaces
        // instead of silently dropping the counter offer.
        guard let price = Double(counterPrice), price > 0 else {
            errorMessage = AppError.validation("Please enter a valid counter offer price").errorDescription
            return
        }

        isLoading = true
        showNegotiation = false

        Task {
            do {
                try await offersRepo.sendCounterOffer(
                    jobId: jobId,
                    offerId: offerId,
                    counterPrice: price,
                    message: negotiationMessage
                )
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = AppError(error).errorDescription
            }
        }
    }

    private func acceptCounterOffer() {
        guard let offerId = offer.id else { return }

        isLoading = true
        Task {
            do {
                try await offersRepo.contractorAcceptsCounter(
                    jobId: jobId,
                    offerId: offerId,
                    finalPrice: offer.counterPrice ?? offer.price
                )
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = AppError(error).errorDescription
            }
        }
    }

    private func declineCounterOffer() {
        guard let offerId = offer.id else { return }

        isLoading = true
        Task {
            do {
                try await offersRepo.contractorDeclinesCounter(jobId: jobId, offerId: offerId)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = AppError(error).errorDescription
            }
        }
    }

    private func finalizeCounterOffer() {
        guard let offerId = offer.id else { return }
        let finalPrice = offer.counterPrice ?? offer.price
        isLoading = true
        Task {
            do {
                try await offersRepo.acceptOfferAndCloseOthers(
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
                errorMessage = AppError(error).errorDescription
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
    .environmentObject(JobsRepository.shared)
    .environmentObject(OffersRepository.shared)
    .environmentObject(ContractorsRepository.shared)
    .environmentObject(ChatRepository.shared)
}

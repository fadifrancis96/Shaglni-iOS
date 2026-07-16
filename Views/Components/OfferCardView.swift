//
//  OfferCardView.swift
//  Shaglni
//
//  The canonical offer row: contractor, status, message, price (with the
//  counter-offer transition when negotiating) and timing.
//

import SwiftUI

struct OfferCardView: View {
    let offer: Offer
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(spacing: DS.Space.m) {
                DSAvatar(name: offer.contractorName, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(offer.contractorName)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                    Text(offer.createdAt, style: .relative)
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkFaint)
                }

                Spacer()

                DSStatusPill(status: offer.status)
            }

            if offer.status == .counterOffer {
                DSBanner(kind: .info, message: L10n.OfferUI.counterReceived.string)
            }

            if !offer.message.isEmpty {
                Text(offer.message)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Divider().overlay(Color.divider)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: DS.Space.s) {
                    DSPriceText(
                        amount: offer.price,
                        tint: offer.counterPrice == nil ? .brand : .inkFaint
                    )

                    if let counterPrice = offer.counterPrice {
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.inkFaint)
                        DSPriceText(amount: counterPrice, tint: .warning)
                    }

                    Spacer()
                }

                if offer.counterPrice != nil {
                    Text(L10n.OfferUI.posterCounter.string)
                        .font(.dsCaption)
                        .foregroundStyle(Color.warning)
                }
            }
        }
        .dsCard()
    }
}

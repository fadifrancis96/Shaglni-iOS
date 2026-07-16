//
//  OfferCardView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct OfferCardView: View {
    let offer: Offer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(offer.contractorName)
                    .font(.headline)
                
                Spacer()
                
                OfferStatusBadge(status: offer.status)
            }
            
            // Counter Offer Alert (for contractors)
            if offer.status == .counterOffer {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(L10n(key: "offerCard.counterReceived").string)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Message
            Text(offer.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Price and Date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(Money.string(offer.price))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        if let counterPrice = offer.counterPrice {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(Money.string(counterPrice))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if offer.counterPrice != nil {
                        Text(L10n(key: "offerCard.posterCounter").string)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(offer.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let respondedAt = offer.respondedAt {
                        Text("\(L10n(key: "offerCard.responded").string) \(respondedAt, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(offer.status == .counterOffer ? Color.orange.opacity(0.05) : Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(offer.status == .counterOffer ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct OfferStatusBadge: View {
    let status: OfferStatus
    
    var body: some View {
        Text(status.localized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(6)
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .rejected: return .red
        case .counterOffer: return .blue
        }
    }
}

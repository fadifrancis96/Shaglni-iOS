//
//  OfferCardView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct OfferCardView: View {
    let offer: Offer
    @EnvironmentObject var localization: LocalizationManager
    
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
                    Text("Counter offer received - Action required")
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
                        Text("₪\(Int(offer.price))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        if let counterPrice = offer.counterPrice {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("₪\(Int(counterPrice))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if offer.counterPrice != nil {
                        Text("Job poster's counter offer")
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
                        Text("Responded \(respondedAt, style: .relative)")
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
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(6)
    }
    
    private var statusText: String {
        switch status {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        case .counterOffer: return "Counter Offer"
        }
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

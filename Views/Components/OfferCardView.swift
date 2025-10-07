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
            
            // Message
            Text(offer.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Price and Date
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("₪\(Int(offer.price))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    if let counterPrice = offer.counterPrice {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption2)
                            Text("Counter: ₪\(Int(counterPrice))")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Text(offer.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
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

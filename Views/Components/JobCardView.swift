//
//  JobCardView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct JobCardView: View {
    let job: Job

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(job.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                StatusBadge(status: job.status)
            }
            
            // Description
            Text(job.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Location and Category
            HStack(spacing: 16) {
                Label(job.location, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let category = job.category {
                    Label(category.localized, systemImage: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Budget and Date
            HStack {
                if let budget = job.budget {
                    Text(Money.string(budget))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text(job.datePosted, style: .relative)
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

struct StatusBadge: View {
    let status: JobStatus
    
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
        case .open: return .green
        case .inProgress: return .orange
        case .completed: return .blue
        }
    }
}

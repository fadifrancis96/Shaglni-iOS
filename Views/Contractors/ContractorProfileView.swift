//
//  ContractorProfileView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct ContractorProfileView: View {
    let contractor: ContractorProfile
    @EnvironmentObject var localization: LocalizationManager
    @State private var completedJobs: [CompletedJob] = []
    @State private var isLoadingJobs = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        )
                    
                    Text(contractor.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let location = contractor.location {
                        Label(location, systemImage: "mappin.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 20) {
                        if let rating = contractor.rating {
                            VStack(spacing: 4) {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", rating))
                                        .fontWeight(.semibold)
                                }
                                Text(localization.localized("rating"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(contractor.completedJobsCount)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(localization.localized("completedJobs"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if contractor.availableForWork {
                        Text(localization.localized("availableForWork"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                Divider()
                
                // Bio
                if !contractor.bio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("bio"))
                            .font(.headline)
                        
                        Text(contractor.bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                // Skills
                if !contractor.skills.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localization.localized("skills"))
                            .font(.headline)
                            .padding(.horizontal)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(contractor.skills, id: \.self) { skill in
                                Text(skill)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Contact Info
                if contractor.contactEmail != nil || contractor.phone != nil || contractor.website != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localization.localized("contactInfo"))
                            .font(.headline)
                        
                        if let email = contractor.contactEmail {
                            Label(email, systemImage: "envelope.fill")
                                .font(.subheadline)
                        }
                        
                        if let phone = contractor.phone {
                            Label(phone, systemImage: "phone.fill")
                                .font(.subheadline)
                        }
                        
                        if let website = contractor.website {
                            Label(website, systemImage: "globe")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                // Portfolio
                VStack(alignment: .leading, spacing: 12) {
                    Text(localization.localized("portfolio"))
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if isLoadingJobs {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if completedJobs.isEmpty {
                        EmptyStateView(
                            icon: "photo.stack",
                            title: "No portfolio items",
                            subtitle: "This contractor hasn't added any work yet"
                        )
                    } else {
                        ForEach(completedJobs) { job in
                            PortfolioItemView(job: job)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadPortfolio)
    }
    
    private func loadPortfolio() {
        guard !contractor.userId.isEmpty else {
            print("Error: Contractor userId is empty")
            return
        }
        
        isLoadingJobs = true
        FirestoreService.shared.fetchCompletedJobs(contractorId: contractor.userId) { result in
            isLoadingJobs = false
            switch result {
            case .success(let jobs):
                completedJobs = jobs
            case .failure(let error):
                print("Error loading portfolio: \(error.localizedDescription)")
            }
        }
    }
}

struct PortfolioItemView: View {
    let job: CompletedJob
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(job.title)
                .font(.headline)
            
            Text(job.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if let category = job.category {
                Text(category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// Simple flow layout for skills
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    NavigationStack {
        ContractorProfileView(contractor: ContractorProfile(
            userId: "1",
            displayName: "Ahmed Al-Rashid",
            bio: "Professional plumber with 10 years of experience",
            skills: ["Plumbing", "Electrical", "HVAC"],
            rating: 4.8,
            completedJobsCount: 45,
            contactEmail: "ahmed@example.com",
            phone: "+966 50 123 4567",
            location: "Riyadh, Saudi Arabia",
            availableForWork: true
        ))
        .environmentObject(LocalizationManager())
    }
}

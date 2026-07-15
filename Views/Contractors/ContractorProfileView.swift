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
        guard !contractor.userId.isEmpty else { return }
        isLoadingJobs = true
        Task {
            do {
                completedJobs = try await PortfolioRepository.shared.fetchPortfolio(contractorId: contractor.userId)
            } catch {
                AppLogger.portfolio.warning("loadPortfolio failed: \(error.localizedDescription, privacy: .public)")
            }
            isLoadingJobs = false
        }
    }
}

struct PortfolioItemView: View {
    let job: CompletedJob
    @State private var selectedImageIndex: Int?
    @State private var showFullScreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Category
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                    
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
                
                Spacer()
                
                if let price = job.finalPrice {
                    Text(Money.string(price))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            // Description
            Text(job.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Images Gallery
            if !job.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Before/After Grid Image (if exists)
                        if let gridURL = job.beforeAfterGridImage {
                            PortfolioImageView(
                                url: gridURL,
                                label: "Before/After",
                                onTap: {
                                    selectedImageIndex = 0
                                    showFullScreen = true
                                }
                            )
                        }
                        
                        // Regular portfolio photos
                        ForEach(Array(job.images.enumerated()), id: \.offset) { index, url in
                            PortfolioImageView(
                                url: url,
                                onTap: {
                                    let offset = job.beforeAfterGridImage != nil ? index + 1 : index
                                    selectedImageIndex = offset
                                    showFullScreen = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else if job.beforeAfterGridImage != nil {
                // Only grid image
                PortfolioImageView(
                    url: job.beforeAfterGridImage!,
                    label: "Before/After",
                    onTap: {
                        selectedImageIndex = 0
                        showFullScreen = true
                    }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showFullScreen) {
            if let selectedIndex = selectedImageIndex {
                let allImages = (job.beforeAfterGridImage != nil ? [job.beforeAfterGridImage!] : []) + job.images
                if selectedIndex < allImages.count {
                    FullScreenPhotoView(
                        photoURLs: allImages,
                        selectedIndex: selectedIndex,
                        isPresented: $showFullScreen
                    )
                }
            }
        }
    }
}

struct PortfolioImageView: View {
    let url: String
    var label: String? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                RemoteThumbnail(urlString: url, size: 120, cornerRadius: 8)
                if let label = label {
                    Text(label)
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.black.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
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
            website: nil,
            profilePicture: nil,
            location: "Riyadh, Saudi Arabia",
            latitude: nil,
            longitude: nil,
            availableForWork: true
        ))
        .environmentObject(LocalizationManager.shared)
    }
}

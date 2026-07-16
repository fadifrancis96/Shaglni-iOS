//
//  ContractorProfileView.swift
//  Shaglni
//
//  Public contractor profile: hero header, stats, bio, skills,
//  contact info and portfolio — composed from the design system.
//

import SwiftUI

struct ContractorProfileView: View {
    let contractor: ContractorProfile
    @EnvironmentObject var localization: LocalizationManager
    @State private var completedJobs: [CompletedJob] = []
    @State private var isLoadingJobs = false

    var body: some View {
        ZStack {
            Color.bgCanvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Space.xl) {
                    heroHeader
                    statRow

                    if !contractor.bio.isEmpty {
                        bioSection
                    }

                    if !contractor.skills.isEmpty {
                        skillsSection
                    }

                    if contractor.contactEmail != nil || contractor.phone != nil || contractor.website != nil {
                        contactSection
                    }

                    portfolioSection
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, DS.Space.l)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadPortfolio)
    }

    // MARK: - Sections

    private var heroHeader: some View {
        VStack(spacing: DS.Space.m) {
            DSAvatar(name: contractor.displayName, urlString: contractor.profilePicture, size: 96)

            VStack(spacing: 6) {
                Text(contractor.displayName)
                    .font(.dsTitle)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)

                if let location = contractor.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                        Text(location)
                    }
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                }
            }

            if let rating = contractor.rating {
                DSRatingStars(rating: rating, size: 14)
            }

            if contractor.availableForWork {
                DSTag(
                    title: localization.localized("availableForWork"),
                    systemImage: "checkmark.circle.fill",
                    tint: .success,
                    background: .successSoft
                )
            }
        }
        .frame(maxWidth: .infinity)
        .dsCard(padding: DS.Space.xl)
    }

    private var statRow: some View {
        HStack(spacing: DS.Space.m) {
            if let rating = contractor.rating {
                DSStatTile(
                    value: String(format: "%.1f", rating),
                    label: localization.localized("rating"),
                    systemImage: "star.fill",
                    tint: .accentWarm,
                    background: .accentWarmSoft
                )
            }
            DSStatTile(
                value: "\(contractor.completedJobsCount)",
                label: localization.localized("completedJobs"),
                systemImage: "checkmark.seal.fill",
                tint: .brand,
                background: .brandSoft
            )
        }
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            DSSectionHeader(title: localization.localized("bio"))

            Text(contractor.bio)
                .font(.dsSub)
                .foregroundStyle(Color.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .dsCard()
        }
    }

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            DSSectionHeader(title: localization.localized("skills"))

            DSFlowLayout(spacing: DS.Space.s) {
                ForEach(contractor.skills, id: \.self) { skill in
                    DSTag(title: skill, tint: .brand, background: .brandSoft)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard()
        }
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            DSSectionHeader(title: localization.localized("contactInfo"))

            VStack(spacing: 0) {
                if let email = contractor.contactEmail {
                    ContactRow(systemImage: "envelope.fill", value: email, tint: .brand)
                    if contractor.phone != nil || contractor.website != nil {
                        Divider().overlay(Color.divider)
                    }
                }
                if let phone = contractor.phone {
                    ContactRow(systemImage: "phone.fill", value: phone, tint: .success)
                    if contractor.website != nil {
                        Divider().overlay(Color.divider)
                    }
                }
                if let website = contractor.website {
                    ContactRow(systemImage: "globe", value: website, tint: .info)
                }
            }
            .dsCard(padding: DS.Space.s)
        }
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            DSSectionHeader(title: localization.localized("portfolio"))

            if isLoadingJobs {
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    Text("Loading")
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                    Text("Loading portfolio items")
                        .font(.dsSub)
                        .foregroundStyle(Color.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsCard()
                .dsSkeleton(when: true)
            } else if completedJobs.isEmpty {
                DSEmptyState(
                    systemImage: "photo.stack",
                    title: "No portfolio items",
                    message: "This contractor hasn't added any work yet"
                )
            } else {
                VStack(spacing: DS.Space.m) {
                    ForEach(completedJobs) { job in
                        PortfolioItemView(job: job)
                    }
                }
            }
        }
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

// MARK: - Contact row

private struct ContactRow: View {
    let systemImage: String
    let value: String
    var tint: Color = .brand

    var body: some View {
        HStack(spacing: DS.Space.m) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                        .fill(tint.opacity(0.13))
                )

            Text(value)
                .font(.dsSub)
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Space.s)
        .padding(.vertical, DS.Space.m)
    }
}

// MARK: - Portfolio item

struct PortfolioItemView: View {
    let job: CompletedJob
    @State private var selectedImageIndex: Int?
    @State private var showFullScreen = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            // Title, category and final price
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(job.title)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)

                    if let category = job.category {
                        DSTag(title: category.localized, systemImage: category.symbol)
                    }
                }

                Spacer(minLength: DS.Space.s)

                if let price = job.finalPrice {
                    DSPriceText(amount: price)
                }
            }

            // Description
            if !job.description.isEmpty {
                Text(job.description)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            // Images gallery
            if !job.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Space.m) {
                        // Before/After grid image (if exists)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard()
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

private struct PortfolioImageView: View {
    let url: String
    var label: String? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                RemoteThumbnail(urlString: url, size: 120, cornerRadius: DS.Radius.thumb)
                if let label = label {
                    Text(label)
                        .font(.dsMicro)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.small, style: .continuous)
                                .fill(Color.black.opacity(0.6))
                        )
                        .padding(DS.Space.xs)
                }
            }
        }
        .buttonStyle(DSPressableStyle())
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

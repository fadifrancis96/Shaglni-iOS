//
//  ContractorListView.swift
//  Shaglni
//
//  Browse contractors: search bar + cards with avatar, rating,
//  availability and skills. Built entirely on the design system.
//

import SwiftUI

struct ContractorListView: View {
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var contractorsRepo: ContractorsRepository
    @State private var searchText = ""
    @State private var selectedSkill: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        DSSearchBar(text: $searchText, placeholder: L10n.Search.contractors.string)

                        if contractorsRepo.allContractors.isEmpty {
                            loadingPlaceholder
                        } else if filteredContractors.isEmpty {
                            DSEmptyState(
                                systemImage: "person.3",
                                title: L10n.Empty.noContractors.string,
                                message: L10n.Empty.tryAdjustSearch.string
                            )
                        } else {
                            LazyVStack(spacing: DS.Space.m) {
                                ForEach(filteredContractors) { contractor in
                                    NavigationLink(destination: ContractorProfileView(contractor: contractor)) {
                                        ContractorCardView(contractor: contractor)
                                    }
                                    .buttonStyle(DSPressableStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.vertical, DS.Space.l)
                }
            }
            .navigationTitle(L10n.Tab.contractors.string)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: DS.Space.m) {
            ForEach(0..<4, id: \.self) { _ in
                ContractorCardView(contractor: .skeletonSample)
            }
        }
        .dsSkeleton(when: true)
    }

    private var filteredContractors: [ContractorProfile] {
        contractorsRepo.allContractors.filter { contractor in
            searchText.isEmpty ||
            contractor.displayName.localizedCaseInsensitiveContains(searchText) ||
            contractor.bio.localizedCaseInsensitiveContains(searchText) ||
            contractor.skills.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

private extension ContractorProfile {
    /// Placeholder used only for redacted skeleton rows while loading.
    static var skeletonSample: ContractorProfile {
        ContractorProfile(
            userId: "",
            displayName: "Contractor Name",
            bio: "",
            skills: ["Skill", "Skill", "Skill"],
            rating: 4.5,
            completedJobsCount: 12,
            contactEmail: nil,
            phone: nil,
            website: nil,
            profilePicture: nil,
            location: "City",
            latitude: nil,
            longitude: nil,
            availableForWork: true
        )
    }
}

private struct ContractorCardView: View {
    let contractor: ContractorProfile
    @EnvironmentObject var localization: LocalizationManager

    private let maxVisibleSkills = 3

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .top, spacing: DS.Space.m) {
                DSAvatar(name: contractor.displayName, urlString: contractor.profilePicture, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(contractor.displayName)
                        .font(.dsHeadline)
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)

                    if let location = contractor.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 11))
                            Text(location)
                                .lineLimit(1)
                        }
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkMuted)
                    }

                    HStack(spacing: DS.Space.s) {
                        if let rating = contractor.rating {
                            DSRatingStars(rating: rating, size: 11)
                        }
                        Text(L10n(key: "contractorList.jobsCount").format(contractor.completedJobsCount))
                            .font(.dsCaption)
                            .foregroundStyle(Color.inkFaint)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: DS.Space.s)

                VStack(alignment: .trailing, spacing: DS.Space.s) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.inkFaint)
                        .flipsForRightToLeftLayoutDirection(true)

                    if contractor.availableForWork {
                        DSTag(
                            title: L10n(key: "contractorList.available").string,
                            systemImage: "checkmark.circle.fill",
                            tint: .success,
                            background: .successSoft
                        )
                    }
                }
            }

            if !contractor.skills.isEmpty {
                HStack(spacing: DS.Space.s) {
                    ForEach(contractor.skills.prefix(maxVisibleSkills), id: \.self) { skill in
                        DSTag(title: skill, tint: .brand, background: .brandSoft)
                    }
                    if contractor.skills.count > maxVisibleSkills {
                        DSTag(title: "+\(contractor.skills.count - maxVisibleSkills)")
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .dsCard()
    }
}

#Preview {
    ContractorListView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(ContractorsRepository.shared)
}

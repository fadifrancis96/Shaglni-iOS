//
//  ContractorDashboardView.swift
//  Shaglni
//
//  Contractor home: greeting, live stats, quick actions and fresh
//  opportunities — all driven by the live repository listeners.
//

import SwiftUI

struct ContractorDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var jobsRepo: JobsRepository
    @EnvironmentObject var offersRepo: OffersRepository

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        greetingHeader

                        HStack(spacing: DS.Space.m) {
                            DSStatTile(
                                value: "\(pendingOffersCount)",
                                label: L10n.OfferStatusL.pending.string,
                                systemImage: "clock.fill",
                                tint: .warning, background: .warningSoft
                            )
                            DSStatTile(
                                value: "\(acceptedOffersCount)",
                                label: L10n.OfferStatusL.accepted.string,
                                systemImage: "checkmark.seal.fill",
                                tint: .success, background: .successSoft
                            )
                            DSStatTile(
                                value: "\(activeJobsCount)",
                                label: L10n.JobStatus.inProgress.string,
                                systemImage: "hammer.fill",
                                tint: .info, background: .infoSoft
                            )
                        }

                        quickActions

                        availableJobs

                        recentOffers
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.bottom, DS.Space.xxl)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Sections

    private var greetingHeader: some View {
        HStack(spacing: DS.Space.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Dash.greetingNow.string)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                Text(authViewModel.currentUserData?.displayName ?? "")
                    .font(.dsTitle)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
            }

            Spacer()

            NavigationLink(destination: ManageProfileView()) {
                DSAvatar(
                    name: authViewModel.currentUserData?.displayName ?? "",
                    urlString: nil,
                    size: 46
                )
            }
        }
        .padding(.top, DS.Space.s)
    }

    private var quickActions: some View {
        VStack(spacing: DS.Space.m) {
            DSSectionHeader(title: L10n.Dash.quickActions.string)

            NavigationLink(destination: MyActiveJobsView()) {
                DashboardActionRow(
                    title: L10n.Action.myActiveJobs.string,
                    systemImage: "hammer.fill",
                    tint: .warning, background: .warningSoft,
                    badge: activeJobsCount > 0 ? "\(activeJobsCount)" : nil
                )
            }
            .buttonStyle(DSPressableStyle())

            NavigationLink(destination: MyPortfolioView()) {
                DashboardActionRow(
                    title: L10n.Action.myPortfolio.string,
                    systemImage: "photo.stack.fill",
                    tint: .accentWarm, background: .accentWarmSoft
                )
            }
            .buttonStyle(DSPressableStyle())

            NavigationLink(destination: ManageProfileView()) {
                DashboardActionRow(
                    title: L10n.Action.manageProfile.string,
                    systemImage: "person.crop.circle.fill",
                    tint: .info, background: .infoSoft
                )
            }
            .buttonStyle(DSPressableStyle())
        }
    }

    private var availableJobs: some View {
        VStack(spacing: DS.Space.m) {
            DSSectionHeader(title: L10n.Section.availableJobs.string)
                .overlay(alignment: .trailing) {
                NavigationLink(destination: JobListView()) {
                    Text(L10n.Action.viewAll.string)
                        .font(.dsCaptionBold)
                        .foregroundStyle(Color.brand)
                }
            }

            if jobsRepo.isLoadingOpenJobs && jobsRepo.openJobs.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    JobCardPlaceholder()
                }
            } else if jobsRepo.openJobs.isEmpty {
                DSEmptyState(
                    systemImage: "briefcase",
                    title: L10n.Empty.noJobsFound.string,
                    message: L10n.Empty.tryFilters.string
                )
                .dsCard()
            } else {
                ForEach(jobsRepo.openJobs.prefix(5)) { job in
                    NavigationLink(destination: JobDetailView(job: job)) {
                        JobCardView(job: job)
                    }
                    .buttonStyle(DSPressableStyle())
                }
            }
        }
    }

    private var recentOffers: some View {
        VStack(spacing: DS.Space.m) {
            DSSectionHeader(title: L10n.Section.myRecentOffers.string)
                .overlay(alignment: .trailing) {
                    NavigationLink(destination: MyOffersView()) {
                        Text(L10n.Action.viewAll.string)
                            .font(.dsCaptionBold)
                            .foregroundStyle(Color.brand)
                    }
                }

            if offersRepo.myOffers.isEmpty {
                DSEmptyState(
                    systemImage: "tag",
                    title: L10n.Empty.noOffers.string,
                    message: L10n.Empty.submitOffers.string
                )
                .dsCard()
            } else {
                ForEach(offersRepo.myOffers.prefix(3)) { offer in
                    OfferCardView(offer: offer)
                }
            }
        }
    }

    // MARK: - Derived stats

    private var pendingOffersCount: Int {
        offersRepo.myOffers.filter { $0.status == .pending }.count
    }

    private var acceptedOffersCount: Int {
        offersRepo.myOffers.filter { $0.status == .accepted }.count
    }

    private var activeJobsCount: Int {
        jobsRepo.myActiveJobs.filter { $0.status == .inProgress }.count
    }
}

/// Skeleton stand-in while job lists load.
struct JobCardPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(spacing: DS.Space.m) {
                RoundedRectangle(cornerRadius: DS.Radius.thumb).fill(Color.surfaceAlt)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.surfaceAlt)
                        .frame(width: 160, height: 14)
                    RoundedRectangle(cornerRadius: 4).fill(Color.surfaceAlt)
                        .frame(width: 90, height: 10)
                }
                Spacer()
            }
            RoundedRectangle(cornerRadius: 4).fill(Color.surfaceAlt)
                .frame(maxWidth: .infinity)
                .frame(height: 10)
        }
        .dsCard()
        .dsSkeleton(when: true)
    }
}

#Preview {
    ContractorDashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
        .environmentObject(OffersRepository.shared)
}

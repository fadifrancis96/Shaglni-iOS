//
//  JobPosterDashboardView.swift
//  Shaglni
//
//  Job-poster home: greeting, hero "post a job" CTA, live stats and
//  recent jobs — all driven by the live repository listeners.
//

import SwiftUI

struct JobPosterDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var jobsRepo: JobsRepository
    @EnvironmentObject var offersRepo: OffersRepository

    @State private var pendingOffersCount = 0
    @State private var showPostJob = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DS.Space.xl) {
                        greetingHeader

                        postJobHero

                        HStack(spacing: DS.Space.m) {
                            DSStatTile(
                                value: "\(count(of: .open))",
                                label: L10n.Dash.statOpenJobs.string,
                                systemImage: "briefcase.fill",
                                tint: .success, background: .successSoft
                            )
                            DSStatTile(
                                value: "\(count(of: .inProgress))",
                                label: L10n.JobStatus.inProgress.string,
                                systemImage: "clock.fill",
                                tint: .warning, background: .warningSoft
                            )
                            DSStatTile(
                                value: "\(pendingOffersCount)",
                                label: L10n.Dash.statOffers.string,
                                systemImage: "tag.fill",
                                tint: .info, background: .infoSoft
                            )
                        }

                        quickActions

                        recentJobs
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.bottom, DS.Space.xxl)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPostJob) { JobFormView() }
            .task { await refreshPendingOffers() }
            .onChange(of: jobsRepo.myPostedJobs) {
                Task { await refreshPendingOffers() }
            }
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

            DSAvatar(name: authViewModel.currentUserData?.displayName ?? "", size: 46)
        }
        .padding(.top, DS.Space.s)
    }

    private var postJobHero: some View {
        Button { showPostJob = true } label: {
            HStack(spacing: DS.Space.l) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.brandDeep)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.white))

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.Action.postJob.string)
                        .font(.dsHeadline)
                        .foregroundStyle(.white)
                    Text(L10n.tagline.string)
                        .font(.dsCaption)
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.forward")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .padding(DS.Space.l)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .fill(LinearGradient.brandHero)
            )
            .shadow(color: Color.brandDeep.opacity(0.3), radius: 14, y: 6)
        }
        .buttonStyle(DSPressableStyle())
    }

    private var quickActions: some View {
        VStack(spacing: DS.Space.m) {
            DSSectionHeader(title: L10n.Dash.quickActions.string)

            NavigationLink(destination: ContractorListView()) {
                DashboardActionRow(
                    title: L10n.Action.findContractor.string,
                    systemImage: "person.2.fill",
                    tint: .info, background: .infoSoft
                )
            }
            .buttonStyle(DSPressableStyle())

            NavigationLink(destination: ReceivedOffersView()) {
                DashboardActionRow(
                    title: L10n.Action.receivedOffers.string,
                    systemImage: "tray.full.fill",
                    tint: .accentWarm, background: .accentWarmSoft,
                    badge: pendingOffersCount > 0 ? "\(pendingOffersCount)" : nil
                )
            }
            .buttonStyle(DSPressableStyle())
        }
    }

    private var recentJobs: some View {
        VStack(spacing: DS.Space.m) {
            DSSectionHeader(title: L10n.Section.recentJobs.string)

            if jobsRepo.myPostedJobs.isEmpty {
                DSEmptyState(
                    systemImage: "briefcase",
                    title: L10n.Empty.noJobs.string,
                    message: L10n.Empty.postFirstJob.string,
                    actionTitle: L10n.Action.postJob.string
                ) { showPostJob = true }
                .dsCard()
            } else {
                ForEach(jobsRepo.myPostedJobs.prefix(5)) { job in
                    NavigationLink(destination: JobDetailView(job: job)) {
                        JobCardView(job: job)
                    }
                    .buttonStyle(DSPressableStyle())
                }
            }
        }
    }

    // MARK: - Data

    private func count(of status: JobStatus) -> Int {
        jobsRepo.myPostedJobs.filter { $0.status == status }.count
    }

    private func refreshPendingOffers() async {
        guard let uid = authViewModel.currentUser?.uid else { return }
        let offers = (try? await offersRepo.fetchOffersForJobPoster(uid, jobs: jobsRepo.myPostedJobs)) ?? []
        pendingOffersCount = offers.filter { $0.offer.status == .pending }.count
    }
}

// MARK: - Shared dashboard row

/// Icon + title row used for dashboard quick actions.
struct DashboardActionRow: View {
    let title: String
    let systemImage: String
    var tint: Color = .brand
    var background: Color = .brandSoft
    var badge: String?

    var body: some View {
        HStack(spacing: DS.Space.l) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous)
                        .fill(background)
                )

            Text(title)
                .font(.dsHeadline)
                .foregroundStyle(Color.ink)

            Spacer()

            if let badge {
                Text(badge)
                    .font(.dsMicro)
                    .foregroundStyle(Color.onBrand)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.brand))
            }

            Image(systemName: "chevron.forward")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkFaint)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .dsCard(padding: DS.Space.m)
    }
}

#Preview {
    JobPosterDashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
        .environmentObject(JobsRepository.shared)
        .environmentObject(OffersRepository.shared)
}

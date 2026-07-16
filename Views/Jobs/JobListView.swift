//
//  JobListView.swift
//  Shaglni
//
//  Browse screen: search, category chips and the live job feed.
//  Job posters see their own jobs; contractors see open jobs.
//

import SwiftUI

struct JobListView: View {
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var jobsRepo: JobsRepository

    @State private var searchText = ""
    @State private var selectedCategory: JobCategory?
    @State private var showMapView = false
    @State private var showPostJob = false

    private var sourceJobs: [Job] {
        authViewModel.isJobPoster ? jobsRepo.myPostedJobs : jobsRepo.openJobs
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search + filters
                    VStack(spacing: DS.Space.m) {
                        DSSearchBar(text: $searchText, placeholder: L10n.Search.jobs.string)
                            .padding(.horizontal, DS.Space.screen)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DS.Space.s) {
                                DSChip(
                                    title: L10n.Filter.all.string,
                                    systemImage: "square.grid.2x2",
                                    isSelected: selectedCategory == nil
                                ) { selectedCategory = nil }

                                ForEach(JobCategory.allCases, id: \.self) { category in
                                    DSChip(
                                        title: category.localized,
                                        systemImage: category.symbol,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    }
                                }
                            }
                            .padding(.horizontal, DS.Space.screen)
                        }
                    }
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.m)

                    // Feed
                    if jobsRepo.isLoadingOpenJobs && sourceJobs.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: DS.Space.m) {
                                ForEach(0..<4, id: \.self) { _ in JobCardPlaceholder() }
                            }
                            .padding(.horizontal, DS.Space.screen)
                        }
                    } else if filteredJobs.isEmpty {
                        ScrollView {
                            DSEmptyState(
                                systemImage: "magnifyingglass",
                                title: L10n.Empty.noJobsFound.string,
                                message: L10n.Empty.tryFilters.string
                            )
                            .padding(.top, 60)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DS.Space.m) {
                                ForEach(filteredJobs) { job in
                                    NavigationLink(destination: JobDetailView(job: job)) {
                                        JobCardView(job: job)
                                    }
                                    .buttonStyle(DSPressableStyle())
                                }
                            }
                            .padding(.horizontal, DS.Space.screen)
                            .padding(.bottom, DS.Space.xxl)
                        }
                    }
                }
            }
            .navigationTitle(L10n.Tab.jobs.string)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showMapView = true } label: {
                        Image(systemName: "map")
                    }
                }
                if authViewModel.isJobPoster {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showPostJob = true } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showMapView) {
                JobMapView(jobs: filteredJobs)
            }
            .sheet(isPresented: $showPostJob) {
                JobFormView()
            }
        }
    }

    private var filteredJobs: [Job] {
        sourceJobs.filter { job in
            let matchesSearch = searchText.isEmpty ||
                job.title.localizedCaseInsensitiveContains(searchText) ||
                job.description.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == nil || job.category == selectedCategory

            return matchesSearch && matchesCategory
        }
    }
}

#Preview {
    JobListView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(AuthViewModel())
        .environmentObject(JobsRepository.shared)
}

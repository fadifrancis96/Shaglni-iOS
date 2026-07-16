//
//  JobListView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct JobListView: View {
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var jobsRepo: JobsRepository
    @State private var searchText = ""
    @State private var selectedCategory: JobCategory?
    @State private var showMapView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search jobs...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(JobCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Jobs List
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredJobs.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "briefcase",
                        title: "No jobs found",
                        subtitle: "Try adjusting your filters"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredJobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle(localization.localized("jobs"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showMapView = true }) {
                        Image(systemName: "map")
                    }
                }
            }
            .sheet(isPresented: $showMapView) {
                JobMapView(jobs: jobs)
            }
        }
    }

    // Job Posters see only their own jobs, Contractors see all open jobs
    private var jobs: [Job] {
        authViewModel.isJobPoster ? jobsRepo.myPostedJobs : jobsRepo.openJobs
    }

    private var isLoading: Bool {
        !authViewModel.isJobPoster && jobsRepo.isLoadingOpenJobs
    }

    private var filteredJobs: [Job] {
        jobs.filter { job in
            let matchesSearch = searchText.isEmpty ||
                job.title.localizedCaseInsensitiveContains(searchText) ||
                job.description.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || job.category == selectedCategory
            
            return matchesSearch && matchesCategory
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

#Preview {
    JobListView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(AuthViewModel())
        .environmentObject(JobsRepository.shared)
}

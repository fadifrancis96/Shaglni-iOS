//
//  ContractorListView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct ContractorListView: View {
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var contractorsRepo: ContractorsRepository
    @State private var searchText = ""
    @State private var selectedSkill: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search contractors...", text: $searchText)
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
                
                // Contractors List
                if filteredContractors.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "person.3",
                        title: "No contractors found",
                        subtitle: "Try adjusting your search"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredContractors) { contractor in
                                NavigationLink(destination: ContractorProfileView(contractor: contractor)) {
                                    ContractorCardView(contractor: contractor)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle(localization.localized("contractors"))
            .navigationBarTitleDisplayMode(.inline)
        }
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

struct ContractorCardView: View {
    let contractor: ContractorProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Profile Picture
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contractor.displayName)
                        .font(.headline)
                    
                    if let location = contractor.location {
                        Label(location, systemImage: "mappin.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        if let rating = contractor.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", rating))
                            }
                            .font(.caption)
                        }
                        
                        Text("• \(contractor.completedJobsCount) jobs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if contractor.availableForWork {
                    Text("Available")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(6)
                }
            }
            
            // Skills
            if !contractor.skills.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(contractor.skills.prefix(4), id: \.self) { skill in
                            Text(skill)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    ContractorListView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(ContractorsRepository.shared)
}

//
//  ProfileView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let userName = authViewModel.currentUserData?.displayName {
                                Text(userName)
                                    .font(.headline)
                            }
                            
                            if let email = authViewModel.currentUser?.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let role = authViewModel.currentUserData?.role {
                                Text(role == .jobPoster ? localization.localized("jobPoster") : localization.localized("contractor"))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Contractor-specific options
                if authViewModel.isContractor {
                    Section {
                        NavigationLink(destination: ManageProfileView()) {
                            Label(localization.localized("manageProfile"), systemImage: "person.text.rectangle")
                        }
                        
                        NavigationLink(destination: MyOffersView()) {
                            Label(localization.localized("myOffers"), systemImage: "doc.text")
                        }
                    }
                }
                
                // Job Poster-specific options
                if authViewModel.isJobPoster {
                    Section {
                        NavigationLink(destination: JobListView()) {
                            Label("My Jobs", systemImage: "briefcase")
                        }
                    }
                }
                
                // Language Settings
                Section(header: Text("Language")) {
                    Picker("Language", selection: $localization.currentLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }
                
                // App Info
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://shaglni.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://shaglni.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Logout
                Section {
                    Button(action: { showLogoutAlert = true }) {
                        HStack {
                            Spacer()
                            Text(localization.localized("logout"))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(localization.localized("profile"))
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}

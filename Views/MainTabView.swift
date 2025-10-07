//
//  MainTabView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    
    var body: some View {
        TabView {
            // Dashboard Tab
            Group {
                if authViewModel.isJobPoster {
                    JobPosterDashboardView()
                } else {
                    ContractorDashboardView()
                }
            }
            .tabItem {
                Label(localization.localized("dashboard"), systemImage: "house.fill")
            }
            
            // Jobs Tab
            JobListView()
                .tabItem {
                    Label(localization.localized("jobs"), systemImage: "briefcase.fill")
                }
            
            // Contractors Tab (Job Posters only)
            if authViewModel.isJobPoster {
                ContractorListView()
                    .tabItem {
                        Label(localization.localized("contractors"), systemImage: "person.3.fill")
                    }
            }
            
            // My Offers Tab (Contractors only)
            if authViewModel.isContractor {
                MyOffersView()
                    .tabItem {
                        Label(localization.localized("myOffers"), systemImage: "doc.text.fill")
                    }
            }
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label(localization.localized("profile"), systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}

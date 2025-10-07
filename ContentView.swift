//
//  ContentView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var localization: LocalizationManager
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.currentUser != nil {
                MainTabView()
            } else {
                LandingView()
            }
        }
        .environment(\.layoutDirection, localization.isRTL ? .rightToLeft : .leftToRight)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("شغلني")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                ProgressView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager())
}

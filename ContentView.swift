//
//  ContentView.swift
//  Shaglni
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            // Bootstrapping covers BOTH "is the auth state known?" AND "did we
            // load the user doc / role?". This eliminates the flash where the
            // tab bar appears for a moment with no role.
            if authViewModel.isBootstrapping {
                LoadingView()
            } else if authViewModel.isReady {
                MainTabView()
            } else if authViewModel.isAuthenticated {
                // Signed in but Firestore user doc not found / failed to decode.
                // Show landing so they can sign out and retry.
                LoadingView()
            } else {
                LandingView()
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                Text(L10n.appName.string)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                ProgressView()
                Text(L10n.Loading.account.string)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
}

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
                // Signed in but the Firestore user doc is missing or failed to decode.
                // The user-doc listener stays live, so if the doc appears this view is
                // replaced automatically; the sign-out button is the manual escape hatch.
                AccountLoadErrorView()
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

struct AccountLoadErrorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                Text(L10n.Auth.accountLoadFailedTitle.string)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(L10n.Auth.accountLoadFailedMessage.string)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button(role: .destructive) {
                    authViewModel.signOut()
                } label: {
                    Text(L10n.Common.logout.string)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
}

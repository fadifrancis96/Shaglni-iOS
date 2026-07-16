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
            LinearGradient.brandHero.ignoresSafeArea()

            VStack(spacing: DS.Space.xl) {
                Image(systemName: "hammer.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)

                Text(L10n.appName.string)
                    .font(.dsHero)
                    .foregroundStyle(.white)

                ProgressView()
                    .tint(.white)

                Text(L10n.Loading.account.string)
                    .font(.dsSub)
                    .foregroundStyle(Color.white.opacity(0.8))
            }
        }
    }
}

struct AccountLoadErrorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color.bgCanvas.ignoresSafeArea()

            VStack(spacing: DS.Space.l) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color.warning)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(Color.warningSoft))

                Text(L10n.Auth.accountLoadFailedTitle.string)
                    .font(.dsTitle2)
                    .foregroundStyle(Color.ink)

                Text(L10n.Auth.accountLoadFailedMessage.string)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Space.xxl)

                Button {
                    authViewModel.signOut()
                } label: {
                    Text(L10n.Common.logout.string)
                }
                .buttonStyle(DSTonalButtonStyle(tint: .danger, background: .dangerSoft))
                .frame(maxWidth: 200)
                .padding(.top, DS.Space.s)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(LocalizationManager.shared)
}

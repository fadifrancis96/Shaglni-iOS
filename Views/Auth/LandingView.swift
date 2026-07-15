//
//  LandingView.swift
//  Shaglni
//

import SwiftUI

struct LandingView: View {
    @EnvironmentObject var localization: LocalizationManager
    @State private var showLogin = false
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        Text(L10n.appName.string)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Text(L10n.tagline.string)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        Button { showRegister = true } label: {
                            Text(L10n.Common.getStarted.string)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button { showLogin = true } label: {
                            HStack {
                                Text(L10n.Common.alreadyHaveAccount.string)
                                    .foregroundColor(.white.opacity(0.9))
                                Text(L10n.Common.signIn.string)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)

                    LanguageSwitcher()
                        .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $showLogin)  { LoginView() }
            .navigationDestination(isPresented: $showRegister) { RegisterView() }
        }
    }
}

struct LanguageSwitcher: View {
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    withAnimation { localization.setLanguage(language) }
                } label: {
                    Text(language.displayName)
                        .font(.caption)
                        .foregroundColor(localization.currentLanguage == language ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            localization.currentLanguage == language ? Color.white.opacity(0.2) : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(LocalizationManager.shared)
}

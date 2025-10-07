//
//  LandingView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct LandingView: View {
    @EnvironmentObject var localization: LocalizationManager
    @State private var showLogin = false
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Logo and Name
                    VStack(spacing: 20) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text(localization.localized("app.name"))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(localization.localized("tagline"))
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            showRegister = true
                        }) {
                            Text(localization.localized("getStarted"))
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showLogin = true
                        }) {
                            HStack {
                                Text(localization.localized("alreadyHaveAccount"))
                                    .foregroundColor(.white.opacity(0.9))
                                Text(localization.localized("signIn"))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    
                    // Language Switcher
                    LanguageSwitcher()
                        .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

struct LanguageSwitcher: View {
    @EnvironmentObject var localization: LocalizationManager
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button(action: {
                    withAnimation {
                        localization.currentLanguage = language
                    }
                }) {
                    Text(language.displayName)
                        .font(.caption)
                        .foregroundColor(localization.currentLanguage == language ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            localization.currentLanguage == language ?
                            Color.white.opacity(0.2) : Color.clear
                        )
                        .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(LocalizationManager())
}

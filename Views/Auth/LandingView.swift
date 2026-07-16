//
//  LandingView.swift
//  Shaglni
//
//  Onboarding: a paged value-proposition carousel on the brand gradient with
//  an inline language switcher, leading into Register / Login.
//

import SwiftUI

struct LandingView: View {
    @EnvironmentObject var localization: LocalizationManager
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var page = 0

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "list.clipboard.fill",
                accessory: "plus.circle.fill",
                title: L10n.Onboarding.page1Title.string,
                subtitle: L10n.Onboarding.page1Subtitle.string
            ),
            OnboardingPage(
                icon: "bubble.left.and.bubble.right.fill",
                accessory: "tag.fill",
                title: L10n.Onboarding.page2Title.string,
                subtitle: L10n.Onboarding.page2Subtitle.string
            ),
            OnboardingPage(
                icon: "checkmark.seal.fill",
                accessory: "star.fill",
                title: L10n.Onboarding.page3Title.string,
                subtitle: L10n.Onboarding.page3Subtitle.string
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.brandHero.ignoresSafeArea()

                // Soft decorative glows for depth.
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 320, height: 320)
                    .blur(radius: 4)
                    .offset(x: 140, y: -300)
                Circle()
                    .fill(Color.black.opacity(0.10))
                    .frame(width: 260, height: 260)
                    .blur(radius: 2)
                    .offset(x: -150, y: 330)

                VStack(spacing: 0) {
                    // Brand row + language switcher
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "hammer.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                            Text(L10n.appName.string)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        LanguageSwitcher()
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, DS.Space.s)

                    // Carousel
                    TabView(selection: $page) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                            OnboardingPageView(page: item)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(Color.white.opacity(index == page ? 1 : 0.35))
                                .frame(width: index == page ? 22 : 7, height: 7)
                        }
                    }
                    .animation(.spring(duration: 0.35), value: page)
                    .padding(.bottom, DS.Space.xxl)

                    // CTAs
                    VStack(spacing: DS.Space.m) {
                        Button { showRegister = true } label: {
                            Text(L10n.Common.getStarted.string)
                                .font(.dsHeadline)
                                .foregroundStyle(Color.brandDeep)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                                        .fill(Color.white)
                                )
                        }
                        .buttonStyle(DSPressableStyle())

                        Button { showLogin = true } label: {
                            HStack(spacing: 6) {
                                Text(L10n.Common.alreadyHaveAccount.string)
                                    .foregroundStyle(Color.white.opacity(0.85))
                                Text(L10n.Common.signIn.string)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .underline()
                            }
                            .font(.dsSub)
                        }
                        .padding(.vertical, DS.Space.s)
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.bottom, DS.Space.l)
                }
            }
            .navigationDestination(isPresented: $showLogin) { LoginView() }
            .navigationDestination(isPresented: $showRegister) { RegisterView() }
        }
    }
}

// MARK: - Pages

private struct OnboardingPage {
    let icon: String
    let accessory: String
    let title: String
    let subtitle: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: DS.Space.xxl) {
            Spacer(minLength: 0)

            // Icon composition: big glass tile with a floating accessory badge.
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 44, style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 168, height: 168)
                    .overlay(
                        RoundedRectangle(cornerRadius: 44, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: page.icon)
                            .font(.system(size: 66, weight: .medium))
                            .foregroundStyle(.white)
                    )

                Image(systemName: page.accessory)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.brandDeep)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color.white))
                    .offset(x: 14, y: -14)
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            }

            VStack(spacing: DS.Space.m) {
                Text(page.title)
                    .font(.dsHero)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)

                Text(page.subtitle)
                    .font(.dsBody)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, DS.Space.xxl)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Language switcher

struct LanguageSwitcher: View {
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    withAnimation { localization.setLanguage(language) }
                } label: {
                    Text(language.displayName)
                        .font(.dsMicro)
                        .foregroundStyle(localization.currentLanguage == language ? Color.brandDeep : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(
                                localization.currentLanguage == language ? Color.white : Color.white.opacity(0.15)
                            )
                        )
                }
            }
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(LocalizationManager.shared)
}

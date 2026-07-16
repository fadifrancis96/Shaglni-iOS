//
//  Theme.swift
//  Shaglni
//
//  Design tokens: colors (light/dark aware), typography scale, spacing, radii,
//  shadows and gradients. Every screen builds on these — never hardcode a hex
//  or a magic corner radius in view code.
//

import SwiftUI

// MARK: - Namespace

enum DS {

    enum Radius {
        /// Cards, sheets, large containers.
        static let card: CGFloat = 20
        /// Buttons, text fields, small containers.
        static let control: CGFloat = 14
        /// Thumbnails, small imagery.
        static let thumb: CGFloat = 12
        /// Tiny elements (badges inside cards).
        static let small: CGFloat = 8
    }

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        /// Default horizontal screen margin.
        static let screen: CGFloat = 20
    }
}

// MARK: - Colors

extension Color {

    /// Dynamic color helper — light and dark variants in one token.
    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func hex(_ value: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    // Brand — deep teal. Confident, trustworthy, distinct from the default iOS blue.
    static let brand = dynamic(light: hex(0x0B7C74), dark: hex(0x2FBFB2))
    /// Text/icons placed on top of a `brand` fill.
    static let onBrand = dynamic(light: .white, dark: hex(0x04302C))
    /// Soft tinted fill for tonal buttons, selected chips, highlights.
    static let brandSoft = dynamic(light: hex(0xE2F3F0), dark: hex(0x14403C))
    /// Strong variant for gradients / pressed states.
    static let brandDeep = dynamic(light: hex(0x075E58), dark: hex(0x1FA396))

    // Accent — warm amber. Ratings, featured content, attention without alarm.
    static let accentWarm = dynamic(light: hex(0xE8950C), dark: hex(0xF5B841))
    static let accentWarmSoft = dynamic(light: hex(0xFDF2DD), dark: hex(0x453413))

    // Surfaces — warm neutrals, not pure gray.
    static let bgCanvas = dynamic(light: hex(0xF6F7F5), dark: hex(0x0F1211))
    static let surface = dynamic(light: .white, dark: hex(0x1A1F1D))
    static let surfaceAlt = dynamic(light: hex(0xEEF0EC), dark: hex(0x242A27))

    // Ink — text hierarchy.
    static let ink = dynamic(light: hex(0x171D1B), dark: hex(0xF1F4F2))
    static let inkMuted = dynamic(light: hex(0x5D6663), dark: hex(0xA3ADA8))
    static let inkFaint = dynamic(light: hex(0x8B9490), dark: hex(0x6E7873))

    static let divider = dynamic(light: hex(0xE4E7E2), dark: hex(0x2C332F))

    // Status
    static let success = dynamic(light: hex(0x188A4C), dark: hex(0x53CE8B))
    static let successSoft = dynamic(light: hex(0xE0F4E8), dark: hex(0x123B26))
    static let warning = dynamic(light: hex(0xC97706), dark: hex(0xF0A93C))
    static let warningSoft = dynamic(light: hex(0xFCF0DC), dark: hex(0x403011))
    static let danger = dynamic(light: hex(0xC93B34), dark: hex(0xF07E77))
    static let dangerSoft = dynamic(light: hex(0xFBE8E6), dark: hex(0x44201D))
    static let info = dynamic(light: hex(0x2563C4), dark: hex(0x7BAAF0))
    static let infoSoft = dynamic(light: hex(0xE4EDFB), dark: hex(0x1B2C47))
}

// MARK: - Gradients

extension LinearGradient {
    /// Hero/brand gradient used on onboarding and headers.
    static let brandHero = LinearGradient(
        colors: [Color.brandDeep, Color.brand],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

extension Font {
    /// Onboarding hero, wordmark.
    static let dsHero = Font.system(size: 34, weight: .heavy, design: .rounded)
    /// Screen titles.
    static let dsTitle = Font.system(size: 26, weight: .bold)
    /// Section titles.
    static let dsTitle2 = Font.system(size: 20, weight: .bold)
    /// Card titles, buttons.
    static let dsHeadline = Font.system(size: 17, weight: .semibold)
    static let dsBody = Font.system(size: 16, weight: .regular)
    static let dsSub = Font.system(size: 15, weight: .regular)
    static let dsCaption = Font.system(size: 13, weight: .regular)
    static let dsCaptionBold = Font.system(size: 13, weight: .semibold)
    /// Overline labels (tiny, tracked, semibold).
    static let dsMicro = Font.system(size: 11, weight: .semibold)
    /// Prices and stats — rounded digits read friendly in every script.
    static let dsPrice = Font.system(size: 17, weight: .bold, design: .rounded)
    static let dsPriceLarge = Font.system(size: 28, weight: .heavy, design: .rounded)
    static let dsStat = Font.system(size: 24, weight: .heavy, design: .rounded)
}

// MARK: - Card & shadow

extension View {
    /// Standard elevated card: surface fill, 20pt radius, hairline stroke, soft shadow.
    func dsCard(padding: CGFloat = DS.Space.l) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .fill(Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .strokeBorder(Color.divider, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    /// Flat inset panel (no shadow) for grouped content inside cards or forms.
    func dsInset(padding: CGFloat = DS.Space.m) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous)
                    .fill(Color.surfaceAlt)
            )
    }
}

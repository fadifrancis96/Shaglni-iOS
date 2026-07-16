//
//  Components.swift
//  Shaglni
//
//  Reusable UI building blocks. Every screen composes these so the app reads
//  as one product: buttons, chips, status pills, avatars, stat tiles,
//  section headers, ratings and price text.
//

import SwiftUI

// MARK: - Buttons

/// Filled brand button — the single most prominent action on a screen.
struct DSPrimaryButtonStyle: ButtonStyle {
    var isDestructive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsHeadline)
            .foregroundStyle(isDestructive ? Color.white : Color.onBrand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(isDestructive ? Color.danger : Color.brand)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Tonal button — secondary actions. Soft brand fill, brand text.
struct DSTonalButtonStyle: ButtonStyle {
    var tint: Color = .brand
    var background: Color = .brandSoft

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsHeadline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(background)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Quiet outline button for low-emphasis actions.
struct DSOutlineButtonStyle: ButtonStyle {
    var tint: Color = .ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsHeadline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(Color.divider, lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Press feedback for tappable cards/rows.
struct DSPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Chips

/// Selectable filter chip (category filters, skills).
struct DSChip: View {
    let title: String
    var systemImage: String?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.dsCaptionBold)
            }
            .foregroundStyle(isSelected ? Color.onBrand : Color.inkMuted)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(isSelected ? Color.brand : Color.surface))
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Color.divider, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

/// Static informational tag (skill labels, metadata).
struct DSTag: View {
    let title: String
    var systemImage: String?
    var tint: Color = .inkMuted
    var background: Color = .surfaceAlt

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(title)
                .font(.dsCaptionBold)
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(background))
    }
}

// MARK: - Status pills

/// Tonal status pill — soft background, colored text. Localized.
struct DSStatusPill: View {
    let text: String
    let tint: Color
    let background: Color

    var body: some View {
        Text(text)
            .font(.dsMicro)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(background))
    }
}

extension DSStatusPill {
    init(status: JobStatus) {
        switch status {
        case .open:
            self.init(text: status.localized, tint: .success, background: .successSoft)
        case .inProgress:
            self.init(text: status.localized, tint: .warning, background: .warningSoft)
        case .completed:
            self.init(text: status.localized, tint: .info, background: .infoSoft)
        }
    }

    init(status: OfferStatus) {
        switch status {
        case .pending:
            self.init(text: status.localized, tint: .warning, background: .warningSoft)
        case .accepted:
            self.init(text: status.localized, tint: .success, background: .successSoft)
        case .rejected:
            self.init(text: status.localized, tint: .danger, background: .dangerSoft)
        case .counterOffer:
            self.init(text: status.localized, tint: .info, background: .infoSoft)
        }
    }
}

// MARK: - Avatar

/// Circular avatar: remote photo when available, otherwise initials on a
/// deterministic per-name gradient. Works with Hebrew/Arabic names.
struct DSAvatar: View {
    let name: String
    var urlString: String?
    var size: CGFloat = 44

    private static let palettes: [[Color]] = [
        [Color(red: 0.05, green: 0.49, blue: 0.46), Color(red: 0.16, green: 0.68, blue: 0.6)],
        [Color(red: 0.85, green: 0.56, blue: 0.09), Color(red: 0.95, green: 0.72, blue: 0.25)],
        [Color(red: 0.2, green: 0.4, blue: 0.75), Color(red: 0.42, green: 0.6, blue: 0.9)],
        [Color(red: 0.63, green: 0.32, blue: 0.71), Color(red: 0.8, green: 0.5, blue: 0.85)],
        [Color(red: 0.78, green: 0.32, blue: 0.3), Color(red: 0.92, green: 0.52, blue: 0.45)]
    ]

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }

    private var palette: [Color] {
        let index = abs(name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }) % Self.palettes.count
        return Self.palettes[index]
    }

    var body: some View {
        Group {
            if let urlString, !urlString.isEmpty {
                RemoteImage(urlString: urlString) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                }
            } else {
                LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(
                        Text(initials.isEmpty ? "•" : initials)
                            .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Stat tile

/// Dashboard metric tile: big rounded number, label, tinted icon bubble.
struct DSStatTile: View {
    let value: String
    let label: String
    let systemImage: String
    var tint: Color = .brand
    var background: Color = .brandSoft

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(Circle().fill(background))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.dsStat)
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(.dsCaption)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard(padding: DS.Space.l)
    }
}

// MARK: - Section header

struct DSSectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.dsTitle2)
                .foregroundStyle(Color.ink)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.dsCaptionBold)
                        .foregroundStyle(Color.brand)
                }
            }
        }
    }
}

// MARK: - Rating

struct DSRatingStars: View {
    let rating: Double
    var size: CGFloat = 12
    var showValue = true

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(Color.accentWarm)
            }
            if showValue {
                Text(String(format: "%.1f", rating))
                    .font(.dsCaptionBold)
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    private func symbol(for index: Int) -> String {
        let value = rating - Double(index)
        if value >= 0.75 { return "star.fill" }
        if value >= 0.25 { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - Price

/// Localized currency text in the rounded numeric style.
struct DSPriceText: View {
    let amount: Double
    var font: Font = .dsPrice
    var tint: Color = .brand

    var body: some View {
        Text(Money.string(amount))
            .font(font)
            .foregroundStyle(tint)
    }
}

// MARK: - Category style

extension JobCategory {
    /// SF Symbol representing the trade.
    var symbol: String {
        switch self {
        case .plumbing:   return "wrench.adjustable.fill"
        case .electrical: return "bolt.fill"
        case .carpentry:  return "hammer.fill"
        case .painting:   return "paintbrush.fill"
        case .cleaning:   return "sparkles"
        case .landscaping: return "leaf.fill"
        case .hvac:       return "fan.fill"
        case .roofing:    return "house.fill"
        case .flooring:   return "square.grid.3x3.fill"
        case .masonry:    return "square.stack.3d.up.fill"
        case .welding:    return "flame.fill"
        case .automotive: return "car.fill"
        case .appliance:  return "refrigerator.fill"
        case .pest:       return "ant.fill"
        case .moving:     return "shippingbox.fill"
        case .other:      return "ellipsis.circle.fill"
        }
    }

    /// Accent tint for the category icon bubble.
    var tint: Color {
        switch self {
        case .plumbing, .cleaning:               return .info
        case .electrical, .welding:              return .accentWarm
        case .carpentry, .flooring, .masonry:    return Color(red: 0.55, green: 0.4, blue: 0.22)
        case .painting:                          return Color(red: 0.63, green: 0.32, blue: 0.71)
        case .landscaping:                       return .success
        case .hvac, .appliance, .automotive:     return .inkMuted
        case .roofing, .moving:                  return .brand
        case .pest:                              return .danger
        case .other:                             return .inkFaint
        }
    }
}

/// Small rounded icon bubble for a job category.
struct DSCategoryIcon: View {
    let category: JobCategory
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(category.tint)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous)
                    .fill(category.tint.opacity(0.14))
            )
    }
}

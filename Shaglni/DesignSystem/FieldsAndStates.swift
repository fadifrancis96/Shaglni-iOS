//
//  FieldsAndStates.swift
//  Shaglni
//
//  Form inputs and screen states: labeled text fields, search bar,
//  empty states, inline error banners and skeleton loading.
//

import SwiftUI

// MARK: - Text field

/// Labeled input with icon, rounded fill and a brand focus ring.
struct DSTextField: View {
    let label: String
    var systemImage: String?
    @Binding var text: String
    var placeholder: String = ""
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never

    @FocusState private var isFocused: Bool
    @State private var revealSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.dsCaptionBold)
                .foregroundStyle(Color.inkMuted)

            HStack(spacing: DS.Space.m) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isFocused ? Color.brand : Color.inkFaint)
                        .frame(width: 20)
                }

                Group {
                    if isSecure && !revealSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text, axis: .vertical)
                            .lineLimit(1...1)
                    }
                }
                .font(.dsBody)
                .foregroundStyle(Color.ink)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(isSecure || keyboard == .emailAddress)
                .textContentType(contentType)
                .focused($isFocused)

                if isSecure {
                    Button { revealSecure.toggle() } label: {
                        Image(systemName: revealSecure ? "eye.slash" : "eye")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.inkFaint)
                    }
                }
            }
            .padding(.horizontal, DS.Space.l)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .fill(Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                    .strokeBorder(isFocused ? Color.brand : Color.divider, lineWidth: isFocused ? 1.5 : 1)
            )
            .animation(.easeOut(duration: 0.15), value: isFocused)
        }
    }
}

/// Multiline input matching DSTextField's look.
struct DSTextEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 110

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.dsCaptionBold)
                .foregroundStyle(Color.inkMuted)

            TextField(placeholder, text: $text, axis: .vertical)
                .font(.dsBody)
                .foregroundStyle(Color.ink)
                .focused($isFocused)
                .frame(minHeight: minHeight, alignment: .topLeading)
                .padding(DS.Space.l)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .fill(Color.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                        .strokeBorder(isFocused ? Color.brand : Color.divider, lineWidth: isFocused ? 1.5 : 1)
                )
                .animation(.easeOut(duration: 0.15), value: isFocused)
        }
    }
}

// MARK: - Search bar

struct DSSearchBar: View {
    @Binding var text: String
    var placeholder: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: DS.Space.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isFocused ? Color.brand : Color.inkFaint)

            TextField(placeholder, text: $text)
                .font(.dsBody)
                .foregroundStyle(Color.ink)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkFaint)
                }
            }
        }
        .padding(.horizontal, DS.Space.l)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .fill(Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .strokeBorder(isFocused ? Color.brand : Color.divider, lineWidth: isFocused ? 1.5 : 1)
        )
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Empty state

/// Friendly full-area empty state with an icon bubble, title, message and optional CTA.
struct DSEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: DS.Space.l) {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Color.brand)
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.brandSoft))

            VStack(spacing: 6) {
                Text(title)
                    .font(.dsHeadline)
                    .foregroundStyle(Color.ink)
                Text(message)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Space.xxl)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(DSTonalButtonStyle())
                .frame(maxWidth: 220)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Error banner

/// Inline error/notice banner for forms and screens.
struct DSBanner: View {
    enum Kind {
        case error, success, info

        var tint: Color {
            switch self {
            case .error: return .danger
            case .success: return .success
            case .info: return .info
            }
        }

        var background: Color {
            switch self {
            case .error: return .dangerSoft
            case .success: return .successSoft
            case .info: return .infoSoft
            }
        }

        var symbol: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    let kind: Kind
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            Image(systemName: kind.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(kind.tint)
            Text(message)
                .font(.dsSub)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DS.Space.l)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                .fill(kind.background)
        )
    }
}

// MARK: - Skeleton loading

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.35), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.7)
                    .offset(x: geo.size.width * phase)
                }
                .allowsHitTesting(false)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}

extension View {
    /// Redacts content and plays a shimmer while `isLoading` is true.
    @ViewBuilder
    func dsSkeleton(when isLoading: Bool) -> some View {
        if isLoading {
            self
                .redacted(reason: .placeholder)
                .modifier(ShimmerModifier())
                .allowsHitTesting(false)
        } else {
            self
        }
    }
}

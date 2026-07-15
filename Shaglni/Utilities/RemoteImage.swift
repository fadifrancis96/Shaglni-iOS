//
//  RemoteImage.swift
//  Shaglni
//
//  A thin wrapper around AsyncImage that adds:
//   - In-memory + URLCache disk caching (via the shared URLSession config)
//   - Consistent placeholder + error treatments
//   - Aspect-fill helper for thumbnails
//

import SwiftUI

/// Loads a remote image with caching and a tasteful placeholder.
/// Backed by the system `URLCache`, which is bumped to 50 MB in-memory / 200 MB on disk in `ShaglniApp.init`.
struct RemoteImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.15))) { phase in
            switch phase {
            case .empty:
                placeholder()
            case .success(let image):
                content(image)
            case .failure:
                placeholder().overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                )
            @unknown default:
                placeholder()
            }
        }
    }
}

extension RemoteImage where Placeholder == DefaultRemoteImagePlaceholder {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(url: url, content: content, placeholder: { DefaultRemoteImagePlaceholder() })
    }

    init(urlString: String?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(url: urlString.flatMap(URL.init(string:)), content: content, placeholder: { DefaultRemoteImagePlaceholder() })
    }
}

struct DefaultRemoteImagePlaceholder: View {
    var body: some View {
        ZStack {
            Color(.systemGray5)
            ProgressView().controlSize(.small)
        }
    }
}

/// Square aspect-fill thumbnail with rounded corners. Replaces hand-rolled `URLSession.dataTask` loaders.
struct RemoteThumbnail: View {
    let urlString: String?
    var size: CGFloat = 80
    var cornerRadius: CGFloat = 8

    var body: some View {
        RemoteImage(urlString: urlString) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

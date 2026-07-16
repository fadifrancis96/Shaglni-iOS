//
//  PhotoGalleryView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI

struct PhotoGalleryView: View {
    let photoURLs: [String]
    let title: String?
    let allowFullScreen: Bool

    @State private var selectedPhotoIndex: Int?
    @State private var showFullScreen = false

    init(
        photoURLs: [String],
        title: String? = nil,
        allowFullScreen: Bool = true
    ) {
        self.photoURLs = photoURLs
        self.title = title
        self.allowFullScreen = allowFullScreen
    }

    var body: some View {
        if !photoURLs.isEmpty {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                if let title = title {
                    Text(title)
                        .font(.dsCaptionBold)
                        .foregroundStyle(Color.inkMuted)
                        .textCase(.uppercase)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Space.m) {
                        ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, url in
                            PhotoThumbnailView(
                                url: url,
                                onTap: allowFullScreen ? {
                                    selectedPhotoIndex = index
                                    showFullScreen = true
                                } : nil
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard()
            .sheet(isPresented: $showFullScreen) {
                if let selectedIndex = selectedPhotoIndex {
                    FullScreenPhotoView(
                        photoURLs: photoURLs,
                        selectedIndex: selectedIndex,
                        isPresented: $showFullScreen
                    )
                }
            }
        }
    }
}

struct PhotoThumbnailView: View {
    let url: String
    let onTap: (() -> Void)?

    var body: some View {
        Button(action: onTap ?? {}) {
            ZStack {
                RemoteThumbnail(urlString: url, size: 84, cornerRadius: DS.Radius.thumb)
                if onTap != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .padding(4)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .padding(4)
                        }
                    }
                }
            }
        }
        .buttonStyle(DSPressableStyle())
    }
}

struct FullScreenPhotoView: View {
    let photoURLs: [String]
    let selectedIndex: Int
    @Binding var isPresented: Bool

    @State private var currentIndex: Int

    init(photoURLs: [String], selectedIndex: Int, isPresented: Binding<Bool>) {
        self.photoURLs = photoURLs
        self.selectedIndex = selectedIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: selectedIndex)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                TabView(selection: $currentIndex) {
                    ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, url in
                        RemoteImage(urlString: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            .navigationTitle("\(currentIndex + 1) / \(photoURLs.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Common.done.string) { isPresented = false }
                        .foregroundStyle(Color.white)
                }
            }
        }
    }
}

#Preview {
    VStack {
        PhotoGalleryView(
            photoURLs: [
                "https://picsum.photos/300/300?random=1",
                "https://picsum.photos/300/300?random=2",
                "https://picsum.photos/300/300?random=3"
            ],
            title: "Job Requirements"
        )

        Spacer()
    }
    .padding()
}

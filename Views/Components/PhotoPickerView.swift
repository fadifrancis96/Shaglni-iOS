//
//  PhotoPickerView.swift
//  Shaglni
//
//  Created on October 2025
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var isPresented: Bool

    let maxPhotos: Int
    let title: String

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(
        selectedImages: Binding<[UIImage]>,
        isPresented: Binding<Bool>,
        maxPhotos: Int = 5,
        title: String = "Select Photos"
    ) {
        self._selectedImages = selectedImages
        self._isPresented = isPresented
        self.maxPhotos = maxPhotos
        self.title = title
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                VStack(spacing: DS.Space.xl) {
                    // Header
                    VStack(spacing: DS.Space.s) {
                        Text(title)
                            .font(.dsTitle2)
                            .foregroundStyle(Color.ink)

                        Text("Select up to \(maxPhotos) photos")
                            .font(.dsSub)
                            .foregroundStyle(Color.inkMuted)
                    }
                    .padding(.top, DS.Space.l)

                    // Photo Picker
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: maxPhotos,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: DS.Space.m) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(Color.brand)

                            Text("Choose Photos")
                                .font(.dsHeadline)
                                .foregroundStyle(Color.brand)

                            Text("From Camera Roll")
                                .font(.dsCaption)
                                .foregroundStyle(Color.inkMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                                .fill(Color.brandSoft)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                                .strokeBorder(Color.brand.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }

                    // Selected Photos Preview
                    if !selectedImages.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Space.m) {
                            HStack {
                                Text("Selected Photos (\(selectedImages.count)/\(maxPhotos))")
                                    .font(.dsHeadline)
                                    .foregroundStyle(Color.ink)

                                Spacer()

                                Button("Clear All") {
                                    selectedImages.removeAll()
                                    selectedItems.removeAll()
                                }
                                .font(.dsCaptionBold)
                                .foregroundStyle(Color.danger)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DS.Space.m) {
                                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                        PhotoPreviewCard(
                                            image: image,
                                            onRemove: {
                                                selectedImages.remove(at: index)
                                                if index < selectedItems.count {
                                                    selectedItems.remove(at: index)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.top, 6)
                                .padding(.trailing, 6)
                            }
                        }
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        DSBanner(kind: .error, message: errorMessage)
                    }

                    Spacer()

                    // Action Buttons
                    VStack(spacing: DS.Space.m) {
                        Button(action: {
                            isPresented = false
                        }) {
                            Text(L10n.Common.done.string)
                        }
                        .buttonStyle(DSPrimaryButtonStyle())
                        .disabled(selectedImages.isEmpty)
                        .opacity(selectedImages.isEmpty ? 0.5 : 1)

                        Button(L10n.Common.cancel.string) {
                            selectedImages.removeAll()
                            selectedItems.removeAll()
                            isPresented = false
                        }
                        .font(.dsSub)
                        .foregroundStyle(Color.inkMuted)
                    }
                    .padding(.bottom, DS.Space.m)
                }
                .padding(.horizontal, DS.Space.screen)
            }
            .navigationBarHidden(true)
            .onChange(of: selectedItems) { newItems in
                loadImages(from: newItems)
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: DS.Space.l) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading photos...")
                            .font(.dsSub)
                            .foregroundStyle(Color.white)
                    }
                }
            }
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) {
        isLoading = true
        errorMessage = nil

        Task {
            var loadedImages: [UIImage] = []

            for item in items {
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        loadedImages.append(image)
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to load some photos"
                    }
                }
            }

            await MainActor.run {
                selectedImages = loadedImages
                isLoading = false
            }
        }
    }
}

struct PhotoPreviewCard: View {
    let image: UIImage
    let onRemove: () -> Void
    @State private var showFullScreen = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                showFullScreen = true
            }) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous))
            }
            .buttonStyle(DSPressableStyle())

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.danger)
                    .background(Circle().fill(Color.surface))
            }
            .offset(x: 5, y: -5)
        }
        .sheet(isPresented: $showFullScreen) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(L10n.Common.done.string) {
                            showFullScreen = false
                        }
                        .foregroundStyle(Color.white)
                    }
                }
            }
        }
    }
}

#Preview {
    PhotoPickerView(
        selectedImages: .constant([]),
        isPresented: .constant(true),
        maxPhotos: 5,
        title: "Job Requirements"
    )
}

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
            VStack(alignment: .leading, spacing: 12) {
                if let title = title {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
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
                    .padding(.horizontal)
                }
            }
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
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadError = false
    
    var body: some View {
        Button(action: onTap ?? {}) {
            ZStack {
                // Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipped()
                        .cornerRadius(8)
                } else if loadError {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Tap indicator
                if onTap != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(4)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageURL = URL(string: url) else {
            loadError = true
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let data = data, let loadedImage = UIImage(data: data) {
                    image = loadedImage
                } else {
                    loadError = true
                }
            }
        }.resume()
    }
}

struct FullScreenPhotoView: View {
    let photoURLs: [String]
    let selectedIndex: Int
    @Binding var isPresented: Bool
    
    @State private var currentIndex: Int
    @State private var images: [UIImage?] = []
    @State private var isLoading = true
    
    init(photoURLs: [String], selectedIndex: Int, isPresented: Binding<Bool>) {
        self.photoURLs = photoURLs
        self.selectedIndex = selectedIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: selectedIndex)
        self._images = State(initialValue: Array(repeating: nil, count: photoURLs.count))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, url in
                            if let image = images[index] {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .tag(index)
                            } else {
                                Color.gray
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                    )
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("Photo \(currentIndex + 1) of \(photoURLs.count)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                loadImages()
            }
        }
    }
    
    private func loadImages() {
        for (index, url) in photoURLs.enumerated() {
            guard let imageURL = URL(string: url) else { continue }
            
            URLSession.shared.dataTask(with: imageURL) { data, response, error in
                DispatchQueue.main.async {
                    if let data = data, let image = UIImage(data: data) {
                        images[index] = image
                    }
                    
                    // Check if all images are loaded
                    if images.allSatisfy({ $0 != nil }) {
                        isLoading = false
                    }
                }
            }.resume()
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

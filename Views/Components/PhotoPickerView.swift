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
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select up to \(maxPhotos) photos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Photo Picker
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: maxPhotos,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("Choose Photos")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("From Camera Roll")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                }
                .padding(.horizontal)
                
                // Selected Photos Preview
                if !selectedImages.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Selected Photos (\(selectedImages.count)/\(maxPhotos))")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Clear All") {
                                selectedImages.removeAll()
                                selectedItems.removeAll()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
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
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedImages.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(selectedImages.isEmpty)
                    
                    Button("Cancel") {
                        selectedImages.removeAll()
                        selectedItems.removeAll()
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onChange(of: selectedItems) { newItems in
                loadImages(from: newItems)
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading photos...")
                            .font(.subheadline)
                            .foregroundColor(.white)
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
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
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
                        Button("Done") {
                            showFullScreen = false
                        }
                        .foregroundColor(.white)
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

//
//  JobCompletionPreviewView.swift
//  Shaglni
//
//  Created on November 2025
//

import SwiftUI
import PhotosUI

struct JobCompletionPreviewView: View {
    let jobWithOffer: JobWithOffer
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var currentStep: CompletionStep = .preview
    @State private var selectedPhotos: [UIImage] = []
    @State private var beforePhotoIndex: Int?
    @State private var afterPhotoIndex: Int?
    @State private var generatedGridImage: UIImage?
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isGeneratingGrid = false
    @State private var skippedBeforeAfter = false
    
    enum CompletionStep {
        case preview
        case photoGallery
        case beforeAfterSelection
        case review
        case success
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Indicator
                    ProgressBar(currentStep: currentStep)
                        .padding()
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch currentStep {
                            case .preview:
                                previewStep
                            case .photoGallery:
                                photoGalleryStep
                            case .beforeAfterSelection:
                                beforeAfterStep
                            case .review:
                                reviewStep
                            case .success:
                                successStep
                            }
                        }
                        .padding()
                    }
                    
                    // Navigation Buttons
                    if currentStep != .success {
                        VStack(spacing: 12) {
                            if currentStep == .preview {
                                Button(action: {
                                    withAnimation {
                                        currentStep = .photoGallery
                                    }
                                }) {
                                    HStack {
                                        Text(L10n(key: "completion.addPhotos").string)
                                            .fontWeight(.semibold)
                                        Image(systemName: "arrow.right")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    dismiss()
                                }) {
                                    Text(L10n(key: "completion.skipForNow").string)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .foregroundColor(.secondary)
                                }
                            } else if currentStep == .photoGallery {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            withAnimation {
                                                currentStep = .preview
                                            }
                                        }) {
                                            Text(L10n.Common.back.string)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color(.systemGray6))
                                                .foregroundColor(.primary)
                                                .cornerRadius(12)
                                        }
                                        
                                        if !selectedPhotos.isEmpty {
                                            Button(action: {
                                                skippedBeforeAfter = false
                                                withAnimation {
                                                    currentStep = .beforeAfterSelection
                                                }
                                            }) {
                                                Text(L10n(key: "completion.createBeforeAfter").string)
                                                    .fontWeight(.semibold)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.blue)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                    
                                    // Skip button - goes directly to review
                                    Button(action: {
                                        skippedBeforeAfter = true
                                        withAnimation {
                                            currentStep = .review
                                        }
                                    }) {
                                        Text(L10n(key: "completion.skipBeforeAfter").string)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .disabled(selectedPhotos.isEmpty)
                                }
                            } else if currentStep == .beforeAfterSelection {
                                VStack(spacing: 12) {
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            withAnimation {
                                                currentStep = .photoGallery
                                            }
                                        }) {
                                            Text(L10n.Common.back.string)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color(.systemGray6))
                                                .foregroundColor(.primary)
                                                .cornerRadius(12)
                                        }
                                        
                                        Button(action: {
                                            if beforePhotoIndex != nil && afterPhotoIndex != nil {
                                                generateBeforeAfterGrid()
                                            }
                                        }) {
                                            if isGeneratingGrid {
                                                ProgressView()
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.blue.opacity(0.7))
                                                    .cornerRadius(12)
                                            } else {
                                                Text(beforePhotoIndex != nil && afterPhotoIndex != nil ? L10n(key: "completion.generateGrid").string : L10n(key: "completion.selectBothPhotos").string)
                                                    .fontWeight(.semibold)
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(beforePhotoIndex != nil && afterPhotoIndex != nil ? Color.blue : Color.gray)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(12)
                                            }
                                        }
                                        .disabled(beforePhotoIndex == nil || afterPhotoIndex == nil || isGeneratingGrid)
                                    }
                                    
                                    if generatedGridImage != nil {
                                        Button(action: {
                                            withAnimation {
                                                currentStep = .review
                                            }
                                        }) {
                                            Text(L10n(key: "completion.continueToReview").string)
                                                .fontWeight(.semibold)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                        }
                                    }
                                    
                                    // Skip button - goes to review without grid
                                    Button(action: {
                                        skippedBeforeAfter = true
                                        withAnimation {
                                            currentStep = .review
                                        }
                                    }) {
                                        Text(L10n(key: "completion.skipBeforeAfter").string)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            } else if currentStep == .review {
                                HStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation {
                                            // Go back to before/after if they didn't skip, otherwise go to photo gallery
                                            currentStep = skippedBeforeAfter ? .photoGallery : .beforeAfterSelection
                                        }
                                    }) {
                                        Text(L10n.Common.back.string)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .foregroundColor(.primary)
                                            .cornerRadius(12)
                                    }
                                    
                                    Button(action: {
                                        saveToProfile()
                                    }) {
                                        if isUploading {
                                            HStack {
                                                ProgressView()
                                                Text("\(Int(uploadProgress * 100))%")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.blue.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                        } else {
                                            Text(L10n(key: "completion.addToProfile").string)
                                                .fontWeight(.semibold)
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                        }
                                    }
                                    .disabled(isUploading)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationTitle(L10n(key: "completion.addToProfile").string)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedPhotoItems) { items in
                loadPhotos(from: items)
            }
        }
    }
    
    // MARK: - Step Views
    
    private var previewStep: some View {
        VStack(spacing: 20) {
            // Celebration Icon
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text(L10n(key: "completion.jobCompleted").string)
                .font(.title)
                .fontWeight(.bold)

            Text(L10n(key: "completion.congratsMessage").string)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Job Preview Card
            VStack(alignment: .leading, spacing: 12) {
                Text(jobWithOffer.job.title)
                    .font(.headline)
                
                Text(jobWithOffer.job.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                if let category = jobWithOffer.job.category {
                    Label(category.localized, systemImage: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                let finalPrice = jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
                HStack {
                    Text(L10n(key: "completion.priceLabel").string)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(Money.string(finalPrice))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var photoGalleryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n(key: "completion.addJobPhotos").string)
                .font(.title2)
                .fontWeight(.bold)

            Text(L10n(key: "completion.uploadPhotosHint").string)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if selectedPhotos.isEmpty {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text(L10n(key: "completion.addPhotos").string)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 100)
                                .clipped()
                                .cornerRadius(8)
                            
                            Button(action: {
                                selectedPhotos.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .padding(4)
                        }
                    }
                    
                    if selectedPhotos.count < 10 {
                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: 10 - selectedPhotos.count,
                            matching: .images
                        ) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                Text(L10n(key: "completion.addMore").string)
                                    .font(.caption)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            var newImages: [UIImage] = []
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    newImages.append(image)
                }
            }
            
            await MainActor.run {
                // Append new photos without duplicates
                for newImage in newImages {
                    if !selectedPhotos.contains(where: { $0.pngData() == newImage.pngData() }) {
                        selectedPhotos.append(newImage)
                    }
                }
                // Clear the picker selection after loading
                selectedPhotoItems.removeAll()
            }
        }
    }
    
    private var beforeAfterStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n(key: "portfolio.beforeAfter").string)
                .font(.title2)
                .fontWeight(.bold)

            Text(L10n(key: "completion.beforeAfterHint").string)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !selectedPhotos.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                        ZStack {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            beforePhotoIndex == index ? Color.green : (afterPhotoIndex == index ? Color.blue : Color.clear),
                                            lineWidth: 4
                                        )
                                )
                            
                            VStack {
                                if beforePhotoIndex == index {
                                    Label(L10n(key: "completion.before").string, systemImage: "arrow.down")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.green)
                                        .cornerRadius(6)
                                } else if afterPhotoIndex == index {
                                    Label(L10n(key: "completion.after").string, systemImage: "arrow.up")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.blue)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .onTapGesture {
                            if beforePhotoIndex == nil {
                                beforePhotoIndex = index
                            } else if afterPhotoIndex == nil && beforePhotoIndex != index {
                                afterPhotoIndex = index
                            } else if beforePhotoIndex == index {
                                beforePhotoIndex = nil
                            } else if afterPhotoIndex == index {
                                afterPhotoIndex = nil
                            }
                        }
                    }
                }
                
                if let gridImage = generatedGridImage {
                    VStack(spacing: 8) {
                        Text(L10n(key: "completion.gridPreview").string)
                            .font(.headline)
                        
                        Image(uiImage: gridImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n(key: "completion.reviewTitle").string)
                .font(.title2)
                .fontWeight(.bold)

            // Job Summary
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n(key: "completion.jobDetails").string)
                    .font(.headline)
                
                Text(jobWithOffer.job.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let category = jobWithOffer.job.category {
                    Label(category.localized, systemImage: "tag.fill")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Photos Summary
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n(key: "completion.photosCount").format(selectedPhotos.count))
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { _, photo in
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Before/After Grid
            if let gridImage = generatedGridImage {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n(key: "completion.beforeAfterGrid").string)
                        .font(.headline)
                    
                    Image(uiImage: gridImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var successStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text(L10n(key: "completion.addedToProfile").string)
                .font(.title)
                .fontWeight(.bold)

            Text(L10n(key: "completion.successMessage").string)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                dismiss()
            }) {
                Text(L10n.Common.done.string)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateBeforeAfterGrid() {
        guard let beforeIndex = beforePhotoIndex,
              let afterIndex = afterPhotoIndex,
              beforeIndex < selectedPhotos.count,
              afterIndex < selectedPhotos.count else { return }
        
        isGeneratingGrid = true
        
        let beforeImage = selectedPhotos[beforeIndex]
        let afterImage = selectedPhotos[afterIndex]
        
        // Use a standard size for consistent grid
        let targetHeight: CGFloat = 800
        let targetWidth: CGFloat = 1600 // 2x width for side by side
        
        // Resize images to same height while maintaining aspect ratio
        let beforeAspect = beforeImage.size.width / beforeImage.size.height
        let afterAspect = afterImage.size.width / afterImage.size.height
        
        let beforeWidth = targetHeight * beforeAspect
        let afterWidth = targetHeight * afterAspect
        let sideWidth = max(beforeWidth, afterWidth)
        
        let finalWidth = sideWidth * 2
        let finalHeight = targetHeight
        
        let size = CGSize(width: finalWidth, height: finalHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        // Draw background
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // Draw before image (left side)
        let beforeRect = CGRect(x: 0, y: 0, width: sideWidth, height: finalHeight)
        beforeImage.draw(in: beforeRect)
        
        // Draw divider line
        UIColor.black.setStroke()
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: sideWidth, y: 0))
        divider.addLine(to: CGPoint(x: sideWidth, y: finalHeight))
        divider.lineWidth = 2
        divider.stroke()
        
        // Draw after image (right side)
        let afterRect = CGRect(x: sideWidth, y: 0, width: sideWidth, height: finalHeight)
        afterImage.draw(in: afterRect)
        
        // Add labels with background
        let font = UIFont.boldSystemFont(ofSize: 32)
        let labelHeight: CGFloat = 50
        
        // Before label background
        UIColor.black.withAlphaComponent(0.7).setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: sideWidth, height: labelHeight))
        
        // After label background
        UIColor.black.withAlphaComponent(0.7).setFill()
        UIRectFill(CGRect(x: sideWidth, y: 0, width: sideWidth, height: labelHeight))
        
        // Draw text
        let beforeAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let afterAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        
        "BEFORE".draw(at: CGPoint(x: 20, y: labelHeight/2 - 16), withAttributes: beforeAttributes)
        "AFTER".draw(at: CGPoint(x: sideWidth + 20, y: labelHeight/2 - 16), withAttributes: afterAttributes)
        
        if let gridImage = UIGraphicsGetImageFromCurrentImageContext() {
            DispatchQueue.main.async {
                self.generatedGridImage = gridImage
                self.isGeneratingGrid = false
            }
        }
    }
    
    private func saveToProfile() {
        guard let contractorId = authViewModel.currentUser?.uid,
              let jobId = jobWithOffer.job.id else { return }

        isUploading = true
        uploadProgress = 0

        Task {
            do {
                let total = Double(selectedPhotos.count + (generatedGridImage != nil ? 1 : 0))
                var uploadedPhotoURLs: [String] = []

                for (index, photo) in selectedPhotos.enumerated() {
                    let url = try await PhotoUploadService.shared.upload(
                        image: photo,
                        to: "completedJobs/\(jobId)/photos/\(UUID().uuidString).jpg"
                    )
                    uploadedPhotoURLs.append(url)
                    await MainActor.run { uploadProgress = Double(index + 1) / total }
                }

                var uploadedGridURL: String?
                if let gridImage = generatedGridImage {
                    uploadedGridURL = try await PhotoUploadService.shared.upload(
                        image: gridImage,
                        to: "completedJobs/\(jobId)/beforeAfter.jpg"
                    )
                    await MainActor.run { uploadProgress = 1.0 }
                }

                let finalPrice = jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
                let completedJob = CompletedJob(
                    contractorId: contractorId,
                    jobId: jobId,
                    title: jobWithOffer.job.title,
                    description: jobWithOffer.job.description,
                    completedDate: Date(),
                    clientName: nil,
                    category: jobWithOffer.job.category,
                    images: uploadedPhotoURLs,
                    beforeAfterGridImage: uploadedGridURL,
                    beforePhotoIndex: beforePhotoIndex,
                    afterPhotoIndex: afterPhotoIndex,
                    finalPrice: finalPrice,
                    location: jobWithOffer.job.location,
                    rating: nil,
                    review: nil
                )

                _ = try await PortfolioRepository.shared.add(completedJob)

                await MainActor.run {
                    isUploading = false
                    withAnimation { currentStep = .success }
                }
            } catch {
                AppLogger.portfolio.error("Failed to publish completed job: \(error.localizedDescription, privacy: .public)")
                await MainActor.run { isUploading = false }
            }
        }
    }
}

struct ProgressBar: View {
    let currentStep: JobCompletionPreviewView.CompletionStep
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach([JobCompletionPreviewView.CompletionStep.preview,
                     .photoGallery,
                     .beforeAfterSelection,
                     .review], id: \.self) { step in
                Circle()
                    .fill(step == currentStep || isCompleted(step) ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    private func isCompleted(_ step: JobCompletionPreviewView.CompletionStep) -> Bool {
        let steps: [JobCompletionPreviewView.CompletionStep] = [.preview, .photoGallery, .beforeAfterSelection, .review]
        if let currentIndex = steps.firstIndex(of: currentStep),
           let stepIndex = steps.firstIndex(of: step) {
            return stepIndex < currentIndex
        }
        return false
    }
}

#Preview {
    JobCompletionPreviewView(jobWithOffer: JobWithOffer(
        job: Job(
            id: "1",
            title: "Kitchen Plumbing",
            description: "Fix leaking pipes",
            location: "Riyadh",
            datePosted: Date(),
            createdBy: "user1",
            status: .completed,
            category: .plumbing
        ),
        offer: Offer(
            id: "1",
            jobId: "1",
            contractorId: "contractor1",
            contractorName: "Ahmed",
            message: "I can do this",
            price: 500,
            status: .accepted,
            createdAt: Date()
        )
    ))
    .environmentObject(AuthViewModel())
}


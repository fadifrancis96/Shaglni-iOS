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

    private var stepIndex: Int {
        switch currentStep {
        case .preview:              return 0
        case .photoGallery:         return 1
        case .beforeAfterSelection: return 2
        case .review, .success:     return 3
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgCanvas.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress Indicator
                    if currentStep != .success {
                        StepProgressBar(current: stepIndex, total: 4)
                            .padding(.horizontal, DS.Space.screen)
                            .padding(.vertical, DS.Space.l)
                    }

                    // Content
                    ScrollView {
                        VStack(spacing: DS.Space.xl) {
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
                        .padding(.horizontal, DS.Space.screen)
                        .padding(.vertical, DS.Space.l)
                    }

                    // Navigation Buttons
                    if currentStep != .success {
                        navigationButtons
                    }
                }
            }
            .navigationTitle("Add to Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedPhotoItems) { items in
                loadPhotos(from: items)
            }
        }
    }

    // MARK: - Bottom navigation bar

    private var navigationButtons: some View {
        VStack(spacing: DS.Space.m) {
            if currentStep == .preview {
                Button {
                    withAnimation {
                        currentStep = .photoGallery
                    }
                } label: {
                    HStack(spacing: DS.Space.s) {
                        Text("Add Photos")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .flipsForRightToLeftLayoutDirection(true)
                    }
                }
                .buttonStyle(DSPrimaryButtonStyle())

                Button {
                    dismiss()
                } label: {
                    Text("Skip for Now")
                        .font(.dsSub)
                        .foregroundStyle(Color.inkMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Space.s)
                }
            } else if currentStep == .photoGallery {
                HStack(spacing: DS.Space.m) {
                    Button {
                        withAnimation {
                            currentStep = .preview
                        }
                    } label: {
                        Text(L10n.Common.back.string)
                    }
                    .buttonStyle(DSOutlineButtonStyle())

                    if !selectedPhotos.isEmpty {
                        Button {
                            skippedBeforeAfter = false
                            withAnimation {
                                currentStep = .beforeAfterSelection
                            }
                        } label: {
                            Text("Create Before/After")
                        }
                        .buttonStyle(DSPrimaryButtonStyle())
                    }
                }

                // Skip button - goes directly to review
                Button {
                    skippedBeforeAfter = true
                    withAnimation {
                        currentStep = .review
                    }
                } label: {
                    Text("Skip Before/After")
                        .font(.dsSub)
                        .foregroundStyle(Color.inkMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Space.s)
                }
                .disabled(selectedPhotos.isEmpty)
            } else if currentStep == .beforeAfterSelection {
                HStack(spacing: DS.Space.m) {
                    Button {
                        withAnimation {
                            currentStep = .photoGallery
                        }
                    } label: {
                        Text(L10n.Common.back.string)
                    }
                    .buttonStyle(DSOutlineButtonStyle())

                    Button {
                        if beforePhotoIndex != nil && afterPhotoIndex != nil {
                            generateBeforeAfterGrid()
                        }
                    } label: {
                        if isGeneratingGrid {
                            ProgressView()
                                .tint(Color.onBrand)
                        } else {
                            Text(beforePhotoIndex != nil && afterPhotoIndex != nil ? "Generate Grid" : "Select Both Photos")
                        }
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .disabled(beforePhotoIndex == nil || afterPhotoIndex == nil || isGeneratingGrid)
                    .opacity(beforePhotoIndex == nil || afterPhotoIndex == nil ? 0.5 : 1)
                }

                if generatedGridImage != nil {
                    Button {
                        withAnimation {
                            currentStep = .review
                        }
                    } label: {
                        Text("Continue to Review")
                    }
                    .buttonStyle(DSTonalButtonStyle(tint: .success, background: .successSoft))
                }

                // Skip button - goes to review without grid
                Button {
                    skippedBeforeAfter = true
                    withAnimation {
                        currentStep = .review
                    }
                } label: {
                    Text("Skip Before/After")
                        .font(.dsSub)
                        .foregroundStyle(Color.inkMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Space.s)
                }
            } else if currentStep == .review {
                HStack(spacing: DS.Space.m) {
                    Button {
                        withAnimation {
                            // Go back to before/after if they didn't skip, otherwise go to photo gallery
                            currentStep = skippedBeforeAfter ? .photoGallery : .beforeAfterSelection
                        }
                    } label: {
                        Text(L10n.Common.back.string)
                    }
                    .buttonStyle(DSOutlineButtonStyle())

                    Button {
                        saveToProfile()
                    } label: {
                        if isUploading {
                            HStack(spacing: DS.Space.s) {
                                ProgressView()
                                    .tint(Color.onBrand)
                                Text("\(Int(uploadProgress * 100))%")
                            }
                        } else {
                            Text("Add to Profile")
                        }
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .disabled(isUploading)
                }
            }
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.vertical, DS.Space.l)
        .background(
            Color.surface
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.divider)
                .frame(height: 1)
        }
    }

    // MARK: - Step Views

    private var previewStep: some View {
        VStack(spacing: DS.Space.xl) {
            // Celebration Icon
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.success)
                .frame(width: 96, height: 96)
                .background(Circle().fill(Color.successSoft))

            VStack(spacing: DS.Space.s) {
                Text("Job Completed!")
                    .font(.dsTitle2)
                    .foregroundStyle(Color.ink)

                Text("Great work! Add this job to your profile to showcase your skills and build your reputation.")
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
            }

            // Job Preview Card
            VStack(alignment: .leading, spacing: DS.Space.m) {
                HStack(alignment: .top, spacing: DS.Space.m) {
                    DSCategoryIcon(category: jobWithOffer.job.category ?? .other)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(jobWithOffer.job.title)
                            .font(.dsHeadline)
                            .foregroundStyle(Color.ink)

                        if let category = jobWithOffer.job.category {
                            DSTag(title: category.localized)
                        }
                    }

                    Spacer(minLength: 0)
                }

                Text(jobWithOffer.job.description)
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(3)

                Divider().overlay(Color.divider)

                HStack(alignment: .firstTextBaseline) {
                    Text(L10n.Field.price.string)
                        .font(.dsCaption)
                        .foregroundStyle(Color.inkMuted)
                    Spacer()
                    DSPriceText(amount: finalPrice, tint: .success)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard()
        }
    }

    private var photoGalleryStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            Text("Add Job Photos")
                .font(.dsTitle2)
                .foregroundStyle(Color.ink)

            Text("Upload photos of your completed work. You can select up to 10 photos.")
                .font(.dsSub)
                .foregroundStyle(Color.inkMuted)

            if selectedPhotos.isEmpty {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    VStack(spacing: DS.Space.m) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(Color.brand)
                            .frame(width: 72, height: 72)
                            .background(Circle().fill(Color.brandSoft))
                        Text("Add Photos")
                            .font(.dsHeadline)
                            .foregroundStyle(Color.brand)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                            .fill(Color.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                            .strokeBorder(Color.brand.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
                    )
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Space.m) {
                    ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 100)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous))

                            Button {
                                selectedPhotos.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.danger)
                                    .background(Circle().fill(Color.surface))
                            }
                            .padding(DS.Space.xs)
                        }
                    }

                    if selectedPhotos.count < 10 {
                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: 10 - selectedPhotos.count,
                            matching: .images
                        ) {
                            VStack(spacing: DS.Space.s) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Add More")
                                    .font(.dsCaptionBold)
                            }
                            .foregroundStyle(Color.brand)
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous)
                                    .fill(Color.brandSoft)
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
        VStack(alignment: .leading, spacing: DS.Space.l) {
            Text("Before & After")
                .font(.dsTitle2)
                .foregroundStyle(Color.ink)

            Text("Select two photos to create a before/after comparison grid. This will be automatically generated for your portfolio.")
                .font(.dsSub)
                .foregroundStyle(Color.inkMuted)

            if !selectedPhotos.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Space.m) {
                    ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { index, photo in
                        ZStack {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous)
                                        .strokeBorder(
                                            beforePhotoIndex == index || afterPhotoIndex == index ? Color.brand : Color.clear,
                                            lineWidth: 3
                                        )
                                )

                            VStack {
                                if beforePhotoIndex == index {
                                    selectionBadge(text: "Before", systemImage: "arrow.down")
                                } else if afterPhotoIndex == index {
                                    selectionBadge(text: "After", systemImage: "arrow.up")
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
                    VStack(spacing: DS.Space.s) {
                        Text("Generated Grid Preview")
                            .font(.dsHeadline)
                            .foregroundStyle(Color.ink)

                        Image(uiImage: gridImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)
                    .dsInset(padding: DS.Space.l)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func selectionBadge(text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.dsMicro)
        }
        .foregroundStyle(Color.onBrand)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.brand))
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: DS.Space.xl) {
            Text("Review & Add")
                .font(.dsTitle2)
                .foregroundStyle(Color.ink)

            // Job Summary
            VStack(alignment: .leading, spacing: DS.Space.m) {
                Text("Job Details")
                    .font(.dsCaptionBold)
                    .foregroundStyle(Color.inkMuted)

                HStack(alignment: .top, spacing: DS.Space.m) {
                    DSCategoryIcon(category: jobWithOffer.job.category ?? .other)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(jobWithOffer.job.title)
                            .font(.dsHeadline)
                            .foregroundStyle(Color.ink)

                        if let category = jobWithOffer.job.category {
                            DSTag(title: category.localized)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard()

            // Photos Summary
            VStack(alignment: .leading, spacing: DS.Space.m) {
                Text("Photos (\(selectedPhotos.count))")
                    .font(.dsCaptionBold)
                    .foregroundStyle(Color.inkMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Space.m) {
                        ForEach(Array(selectedPhotos.enumerated()), id: \.offset) { _, photo in
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsCard()

            // Before/After Grid
            if let gridImage = generatedGridImage {
                VStack(alignment: .leading, spacing: DS.Space.m) {
                    Text("Before & After Grid")
                        .font(.dsCaptionBold)
                        .foregroundStyle(Color.inkMuted)

                    Image(uiImage: gridImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.thumb, style: .continuous))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .dsCard()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var successStep: some View {
        VStack(spacing: DS.Space.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(Color.success)
                .frame(width: 112, height: 112)
                .background(Circle().fill(Color.successSoft))
                .padding(.top, DS.Space.xxl)

            VStack(spacing: DS.Space.s) {
                Text("Added to Profile!")
                    .font(.dsTitle)
                    .foregroundStyle(Color.ink)

                Text("This job has been successfully added to your profile and is now visible to potential clients.")
                    .font(.dsSub)
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
            }

            Button {
                dismiss()
            } label: {
                Text(L10n.Common.done.string)
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .padding(.top, DS.Space.l)
        }
    }

    private var finalPrice: Double {
        jobWithOffer.offer.finalPrice ?? jobWithOffer.offer.counterPrice ?? jobWithOffer.offer.price
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

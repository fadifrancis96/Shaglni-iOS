//
//  PhotoUploadService.swift
//  Shaglni
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseAuth

enum PhotoUploadError: LocalizedError {
    case compressionFailed
    case urlGenerationFailed
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .compressionFailed:   return "Failed to compress image"
        case .urlGenerationFailed: return "Failed to generate download URL"
        case .notAuthenticated:    return "Not authenticated"
        }
    }
}

final class PhotoUploadService {
    static let shared = PhotoUploadService()
    private let storage = Storage.storage()
    private init() {}

    // MARK: - Public async API

    /// Upload a single image. Returns the download URL.
    func upload(image: UIImage, to path: String, quality: ImageQuality = .standard) async throws -> String {
        guard Auth.auth().currentUser != nil else { throw PhotoUploadError.notAuthenticated }
        guard let data = compress(image: image, quality: quality) else {
            throw PhotoUploadError.compressionFailed
        }
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        AppLogger.storage.info("Uploading \(data.count) bytes → \(path, privacy: .public)")
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    /// Upload many images in parallel; returns URLs in the order the source images were provided.
    func uploadAll(_ images: [UIImage], pathPrefix: String, quality: ImageQuality = .standard) async throws -> [String] {
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (idx, image) in images.enumerated() {
                group.addTask {
                    let url = try await self.upload(image: image, to: "\(pathPrefix)/photo_\(idx + 1).jpg", quality: quality)
                    return (idx, url)
                }
            }
            var urls = Array<String?>(repeating: nil, count: images.count)
            for try await (idx, url) in group { urls[idx] = url }
            return urls.compactMap { $0 }
        }
    }

    func uploadJobRequirementPhotos(jobId: String, images: [UIImage]) async throws -> [String] {
        try await uploadAll(images, pathPrefix: "jobs/\(jobId)/requirements")
    }

    func uploadPortfolioPhotos(contractorId: String, images: [UIImage]) async throws -> [String] {
        try await uploadAll(images, pathPrefix: "contractors/\(contractorId)/portfolio")
    }

    func uploadProfilePicture(userId: String, image: UIImage) async throws -> String {
        try await upload(image: image, to: "users/\(userId)/profile/profile_picture.jpg", quality: .high)
    }

    // MARK: - Delete

    func delete(url: String) async {
        do {
            try await storage.reference(forURL: url).delete()
        } catch {
            AppLogger.storage.warning("Failed to delete \(url, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func deleteAll(urls: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls { group.addTask { await self.delete(url: url) } }
        }
    }

    // MARK: - Compression

    enum ImageQuality {
        case standard   // good balance for job + portfolio photos
        case high       // profile pictures

        var maxDimension: CGFloat {
            switch self {
            case .standard: return 1200
            case .high:     return 1920
            }
        }
        var compressionQuality: CGFloat {
            switch self {
            case .standard: return 0.7
            case .high:     return 0.85
            }
        }
    }

    private func compress(image: UIImage, quality: ImageQuality) -> Data? {
        resize(image, maxDimension: quality.maxDimension)
            .jpegData(compressionQuality: quality.compressionQuality)
    }

    private func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }
        let ratio = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.8)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}

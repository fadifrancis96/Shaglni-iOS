//
//  PhotoUploadService.swift
//  Shaglni
//
//  Created on October 2025
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseAuth

class PhotoUploadService {
    static let shared = PhotoUploadService()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Upload Methods
    
    func uploadJobRequirementPhotos(jobId: String, photos: [UIImage], completion: @escaping (Result<[String], Error>) -> Void) {
        uploadPhotos(
            photos: photos,
            path: "jobs/\(jobId)/requirements",
            completion: completion
        )
    }
    
    func uploadContractorPortfolioPhotos(contractorId: String, photos: [UIImage], completion: @escaping (Result<[String], Error>) -> Void) {
        uploadPhotos(
            photos: photos,
            path: "contractors/\(contractorId)/portfolio",
            completion: completion
        )
    }
    
    func uploadProfilePicture(userId: String, photo: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        uploadPhoto(
            photo: photo,
            path: "users/\(userId)/profile/profile_picture.jpg",
            completion: completion
        )
    }
    
    // MARK: - Private Upload Methods
    
    private func uploadPhotos(photos: [UIImage], path: String, completion: @escaping (Result<[String], Error>) -> Void) {
        var uploadedURLs: [String] = []
        var uploadErrors: [Error] = []
        let group = DispatchGroup()
        
        for (index, photo) in photos.enumerated() {
            group.enter()
            
            let photoPath = "\(path)/photo_\(index + 1).jpg"
            uploadPhoto(photo: photo, path: photoPath) { result in
                switch result {
                case .success(let url):
                    uploadedURLs.append(url)
                case .failure(let error):
                    uploadErrors.append(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if uploadErrors.isEmpty {
                completion(.success(uploadedURLs))
            } else {
                completion(.failure(uploadErrors.first!))
            }
        }
    }
    
    private func uploadPhoto(photo: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = compressImage(photo) else {
            completion(.failure(PhotoUploadError.compressionFailed))
            return
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload with progress tracking
        let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Photo upload failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Get download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Failed to get download URL: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(PhotoUploadError.urlGenerationFailed))
                    return
                }
                
                print("✅ Photo uploaded successfully: \(downloadURL.absoluteString)")
                completion(.success(downloadURL.absoluteString))
            }
        }
        
        // Optional: Track upload progress
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            print("📤 Upload progress: \(Int(percentComplete))%")
        }
    }
    
    // MARK: - Image Compression
    
    private func compressImage(_ image: UIImage, quality: CGFloat = 0.8, maxDimension: CGFloat = 1920) -> Data? {
        // Resize image if needed
        let resizedImage = resizeImage(image, maxDimension: maxDimension)
        
        // Compress image
        return resizedImage.jpegData(compressionQuality: quality)
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // If image is already smaller than max dimension, return original
        if max(size.width, size.height) <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // Create new image with new size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Delete Methods
    
    func deletePhoto(url: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = storage.reference(forURL: url)
        
        storageRef.delete { error in
            if let error = error {
                print("❌ Failed to delete photo: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Photo deleted successfully")
                completion(.success(()))
            }
        }
    }
    
    func deleteJobRequirementPhotos(jobId: String, photoURLs: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        let group = DispatchGroup()
        var errors: [Error] = []
        
        for url in photoURLs {
            group.enter()
            deletePhoto(url: url) { result in
                if case .failure(let error) = result {
                    errors.append(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(()))
            } else {
                completion(.failure(errors.first!))
            }
        }
    }
}

// MARK: - Error Types

enum PhotoUploadError: LocalizedError {
    case compressionFailed
    case urlGenerationFailed
    case invalidImage
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .urlGenerationFailed:
            return "Failed to generate download URL"
        case .invalidImage:
            return "Invalid image data"
        case .uploadFailed:
            return "Photo upload failed"
        }
    }
}

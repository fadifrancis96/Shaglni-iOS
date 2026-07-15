//
//  FirestoreDecoding.swift
//  Shaglni
//
//  Tiny helpers shared by the repository layer.
//

import Foundation
import FirebaseFirestore

extension QuerySnapshot {
    /// Decodes documents to a typed array, logging (but not throwing on) decoding failures
    /// so a single bad document doesn't poison the entire list.
    func decoded<T: Decodable>(as type: T.Type) -> [T] {
        documents.compactMap { doc in
            do {
                return try doc.data(as: T.self)
            } catch {
                AppLogger.general.error("Failed to decode \(String(describing: T.self)) document \(doc.documentID, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
    }
}

extension DocumentSnapshot {
    func decode<T: Decodable>(as type: T.Type) throws -> T {
        guard exists else { throw AppError.notFound(String(describing: T.self)) }
        return try data(as: T.self)
    }
}

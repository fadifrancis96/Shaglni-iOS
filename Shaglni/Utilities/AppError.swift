//
//  AppError.swift
//  Shaglni
//

import Foundation

/// User-facing error type. Always carries a localized message ready for UI.
enum AppError: LocalizedError, Equatable {
    case notAuthenticated
    case notAuthorized
    case notFound(String)
    case validation(String)
    case network(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:        return L10n(key: "error.notAuthenticated").string
        case .notAuthorized:           return L10n(key: "error.notAuthorized").string
        case .notFound(let what):      return L10n(key: "error.notFound %@").format(what)
        case .validation(let detail):  return detail
        case .network(let detail):     return detail
        case .unknown(let detail):     return detail
        }
    }

    init(_ error: Error) {
        if let appError = error as? AppError {
            self = appError
        } else {
            self = .unknown(error.localizedDescription)
        }
    }
}

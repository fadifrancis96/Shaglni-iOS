//
//  AppLogger.swift
//  Shaglni
//

import Foundation
import OSLog

/// Centralised logger. Each domain gets its own subsystem-category combo for filtering in Console.app.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.shaglni.app.Shaglni"

    static let auth        = Logger(subsystem: subsystem, category: "auth")
    static let jobs        = Logger(subsystem: subsystem, category: "jobs")
    static let offers      = Logger(subsystem: subsystem, category: "offers")
    static let contractors = Logger(subsystem: subsystem, category: "contractors")
    static let portfolio   = Logger(subsystem: subsystem, category: "portfolio")
    static let chat        = Logger(subsystem: subsystem, category: "chat")
    static let storage     = Logger(subsystem: subsystem, category: "storage")
    static let ui          = Logger(subsystem: subsystem, category: "ui")
    static let general     = Logger(subsystem: subsystem, category: "general")
}

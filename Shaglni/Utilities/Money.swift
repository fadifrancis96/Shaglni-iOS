//
//  Money.swift
//  Shaglni
//

import Foundation

/// Single source of truth for currency formatting.
/// Default currency is Israeli New Shekel; we render it as `₪1,234` (no fractional part for whole shekels).
enum Money {
    static let currencyCode = "ILS"
    static let currencySymbol = "₪"

    private static let wholeShekelFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.currencySymbol = currencySymbol
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()

    private static let preciseFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.currencySymbol = currencySymbol
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    /// Whole-shekel formatting: `₪1,234`. Use this in lists/cards/badges.
    static func string(_ value: Double) -> String {
        wholeShekelFormatter.string(from: NSNumber(value: value)) ?? "\(currencySymbol)\(Int(value))"
    }

    /// Two-decimal formatting: `₪1,234.50`. Use this when displaying user-entered prices.
    static func precise(_ value: Double) -> String {
        preciseFormatter.string(from: NSNumber(value: value)) ?? "\(currencySymbol)\(value)"
    }
}

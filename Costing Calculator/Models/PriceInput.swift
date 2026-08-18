//
//  PriceInput.swift
//  Costing Calculator
//

import Foundation

/// A price that can be given two ways: straight in Rupiah, or in RMB together
/// with an exchange rate to convert it. The RMB pair takes over once both
/// halves are filled in, so a converted price always beats the direct one.
struct PriceInput: Codable, Hashable {
    /// Entered directly in Rupiah.
    var rupiah: Double = 0
    /// Entered in Chinese Yuan instead.
    var rmb: Double = 0
    /// Rupiah per RMB. Needed before an RMB price can be used.
    var exchangeRate: Double = 0

    /// The RMB price in Rupiah, once there is a rate to convert it with.
    var converted: Double? {
        guard rmb > 0, exchangeRate > 0 else { return nil }
        return rmb * exchangeRate
    }

    /// What the costing actually uses.
    var value: Double {
        converted ?? rupiah
    }

    var isConverted: Bool {
        converted != nil
    }

    /// Notes the RMB price behind a converted figure, for summary lines.
    var origin: String {
        isConverted ? " (¥\(rmb.compact) @ \(exchangeRate.compact))" : ""
    }
}

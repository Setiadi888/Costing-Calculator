//
//  CostCategory.swift
//  Costing Calculator
//

import Foundation

/// Fixed rates the costing sheet is built on.
enum CostRates {
    /// Cost of running an injection machine for one day.
    static let injectionPerDay: Double = 1_500_000
    static let secondsPerDay: Double = 86_400
    /// Freight charged per cubic metre of carton volume.
    static let freightPerCubicMetre: Double = 3_500_000
    /// Miscellaneous is added on top of every other cost.
    static let miscellaneousRate: Double = 0.075
}

enum MouldingMaterial: String, CaseIterable, Identifiable, Codable {
    case pp = "PP"
    case abs = "ABS"

    var id: String { rawValue }

    /// Material price per kilogram.
    var ratePerKg: Double {
        switch self {
        case .pp: return 28_000
        case .abs: return 30_000
        }
    }
}

enum CostCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case injectionPart = "INJECTION PART"
    case sparePart = "SPAREPART"
    case packaging = "PACKAGING"
    case uv = "UV"
    case spray = "SPRAY"
    case padPrint = "PAD PRINT"
    case packagingLabourCost = "PACKAGING LABOUR COST"
    case assemblyLabourCost = "ASSEMBLY LABOUR COST"

    var id: String { rawValue }
}

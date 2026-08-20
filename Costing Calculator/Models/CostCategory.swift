//
//  CostCategory.swift
//  Costing Calculator
//

import Foundation

/// Fixed rates the costing sheet is built on.
enum CostRates {
    /// Cost of running an injection machine for one day, picked per item.
    static let injectionPerDayOptions: [Double] = [
        1_500_000, 1_600_000, 1_700_000, 1_800_000, 2_000_000
    ]
    static let defaultInjectionPerDay: Double = 1_500_000
    static let secondsPerDay: Double = 86_400
    /// Freight charged per cubic metre of carton volume, editable per item.
    static let defaultFreightPerCubicMetre: Double = 3_500_000
    /// Miscellaneous is added on top of every other cost.
    static let miscellaneousRate: Double = 0.075
    /// Added to an injection part's material cost when the form's box is
    /// ticked. Left off unless it is asked for.
    static let materialExtraRate: Double = 0.03
}

enum MouldingMaterial: String, CaseIterable, Identifiable, Codable {
    case pp = "PP"
    case abs = "ABS"
    case asResin = "AS"
    case ps = "PS"
    case pvc = "PVC"

    var id: String { rawValue }

    /// The rate the form starts from, for the materials that have a standing
    /// one. The rest are priced by hand: their price is the thing that moves,
    /// and a stale default costs more than an empty field does.
    var defaultRatePerKg: Double? {
        switch self {
        case .pp: return 28_000
        case .abs: return 30_000
        case .asResin, .ps, .pvc: return nil
        }
    }
}

/// What an imported item actually is. Sparepart, packaging and product are
/// costed the same way, so they share one category and are told apart by this.
enum ImportKind: String, CaseIterable, Identifiable, Hashable, Codable {
    case sparePart = "SPAREPART"
    case packaging = "PACKAGING"
    case product = "PRODUCT"

    var id: String { rawValue }
}

enum CostCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case injectionPart = "INJECTION PART"
    case importItem = "IMPORT"
    case uv = "UV"
    case spray = "SPRAY"
    case padPrint = "PAD PRINT"
    case packagingLabourCost = "PACKAGING LABOUR COST"
    case assemblyLabourCost = "ASSEMBLY LABOUR COST"

    var id: String { rawValue }
}

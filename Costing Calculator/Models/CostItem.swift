//
//  CostItem.swift
//  Costing Calculator
//

import Foundation

/// The per-category inputs a cost is worked out from.
enum CostDetails: Codable, Hashable {
    /// Material cost plus machine time. INJECTION PART.
    case injection(weightGrams: Double, cycleTimeSeconds: Double, cavities: Double, material: MouldingMaterial)
    /// Unit cost plus the carton's share of freight. SPAREPART and PACKAGING.
    case cartoned(unitCost: Double, pcsPerCarton: Double, cubicMetres: Double)
    /// A table's cost spread over the pieces it holds. UV.
    case perTable(costPerTable: Double, pcsPerTable: Double)
    /// A figure entered directly. SPRAY, PAD PRINT and both labour costs.
    case flat(amount: Double)

    /// Cost of one piece, in Rupiah.
    var subtotal: Double {
        switch self {
        case let .injection(weightGrams, cycleTimeSeconds, cavities, material):
            let materialCost = (weightGrams / 1_000) * material.ratePerKg
            guard cavities > 0 else { return materialCost }
            let costPerSecond = CostRates.injectionPerDay / CostRates.secondsPerDay
            return materialCost + costPerSecond * cycleTimeSeconds / cavities

        case let .cartoned(unitCost, pcsPerCarton, cubicMetres):
            guard pcsPerCarton > 0 else { return unitCost }
            return unitCost + (cubicMetres * CostRates.freightPerCubicMetre / pcsPerCarton)

        case let .perTable(costPerTable, pcsPerTable):
            guard pcsPerTable > 0 else { return 0 }
            return costPerTable / pcsPerTable

        case let .flat(amount):
            return amount
        }
    }

    /// Short description of the inputs, shown under the item name.
    var summary: String {
        switch self {
        case let .injection(weightGrams, cycleTimeSeconds, cavities, material):
            return "\(weightGrams.compact) g \(material.rawValue) · \(cycleTimeSeconds.compact) s · \(cavities.compact) cav"
        case let .cartoned(unitCost, pcsPerCarton, cubicMetres):
            return "\(unitCost.rupiah)/pc · \(pcsPerCarton.compact) pcs/ctn · \(cubicMetres.compact) m³"
        case let .perTable(costPerTable, pcsPerTable):
            return "\(costPerTable.rupiah)/table · \(pcsPerTable.compact) pcs/table"
        case .flat:
            return ""
        }
    }
}

struct CostItem: Identifiable, Codable {
    let id: UUID
    var category: CostCategory
    var name: String
    var details: CostDetails

    var subtotal: Double { details.subtotal }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? category.rawValue.capitalized : trimmed
    }

    init(id: UUID = UUID(), category: CostCategory, name: String, details: CostDetails) {
        self.id = id
        self.category = category
        self.name = name
        self.details = details
    }
}

extension Double {
    /// Rupiah, using Indonesian separators.
    var rupiah: String {
        "Rp " + formatted(
            .number
                .precision(.fractionLength(0...2))
                .locale(Locale(identifier: "id_ID"))
        )
    }

    /// Plain number with trailing zeroes dropped.
    var compact: String {
        formatted(.number.precision(.fractionLength(0...2)))
    }
}

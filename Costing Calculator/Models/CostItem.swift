//
//  CostItem.swift
//  Costing Calculator
//

import Foundation

/// The two halves of an injection part's cost, kept separate so the form can
/// show a sub total under each section.
struct InjectionBreakdown {
    var weightGrams: Double
    var cycleTimeSeconds: Double
    var cavities: Double
    var material: MouldingMaterial
    var costPerDay: Double

    /// Weight converted to kilos at the material's rate.
    var materialCost: Double {
        (weightGrams / 1_000) * material.ratePerKg
    }

    /// Cycles the machine completes in a day.
    var cyclesPerDay: Double {
        guard cycleTimeSeconds > 0 else { return 0 }
        return CostRates.secondsPerDay / cycleTimeSeconds
    }

    /// Pieces produced in a day: every cycle fills every cavity.
    var piecesPerDay: Double {
        cyclesPerDay * cavities
    }

    /// The day's machine cost split across the day's output.
    var injectCost: Double {
        guard piecesPerDay > 0 else { return 0 }
        return costPerDay / piecesPerDay
    }

    var totalPartCost: Double {
        materialCost + injectCost
    }
}

/// The two halves of a cartoned item's cost, kept separate so the form can
/// show a sub total under each section.
struct CartonBreakdown {
    var unitCost: Double
    var pcsPerCarton: Double
    var cubicMetres: Double

    /// What the piece itself costs.
    var productCost: Double {
        unitCost
    }

    /// The piece's share of the carton's freight.
    var importCost: Double {
        guard pcsPerCarton > 0 else { return 0 }
        return cubicMetres * CostRates.freightPerCubicMetre / pcsPerCarton
    }

    var totalCost: Double {
        productCost + importCost
    }
}

/// The per-category inputs a cost is worked out from.
enum CostDetails: Codable, Hashable {
    /// Material cost plus machine time. INJECTION PART.
    case injection(
        weightGrams: Double,
        cycleTimeSeconds: Double,
        cavities: Double,
        material: MouldingMaterial,
        costPerDay: Double
    )
    /// Unit cost plus the carton's share of freight. SPAREPART and PACKAGING.
    case cartoned(unitCost: Double, pcsPerCarton: Double, cubicMetres: Double)
    /// A table's cost spread over the pieces it holds. UV.
    case perTable(costPerTable: Double, pcsPerTable: Double)
    /// A figure entered directly. SPRAY, PAD PRINT and both labour costs.
    case flat(amount: Double)

    /// Cost of one piece, in Rupiah.
    var subtotal: Double {
        switch self {
        case let .injection(weightGrams, cycleTimeSeconds, cavities, material, costPerDay):
            return InjectionBreakdown(
                weightGrams: weightGrams,
                cycleTimeSeconds: cycleTimeSeconds,
                cavities: cavities,
                material: material,
                costPerDay: costPerDay
            ).totalPartCost

        case let .cartoned(unitCost, pcsPerCarton, cubicMetres):
            return CartonBreakdown(
                unitCost: unitCost,
                pcsPerCarton: pcsPerCarton,
                cubicMetres: cubicMetres
            ).totalCost

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
        case let .injection(weightGrams, cycleTimeSeconds, cavities, material, costPerDay):
            return "\(weightGrams.compact) g \(material.rawValue) · \(cycleTimeSeconds.compact) s · \(cavities.compact) cav · \(costPerDay.rupiah)/day"
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

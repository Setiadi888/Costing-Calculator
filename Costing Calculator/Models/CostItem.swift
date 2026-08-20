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
    /// Rate per kilo as entered on the form, starting from the material's
    /// standing rate where it has one. Can be given in RMB with an exchange
    /// rate instead.
    var materialPrice: PriceInput
    /// Adds 3% on top of the material cost when ticked on the form.
    var addsExtra: Bool = false

    var ratePerKg: Double {
        materialPrice.value
    }

    /// Weight converted to kilos at the material's rate, with the 3% on top
    /// when it is being added.
    var materialCost: Double {
        let base = (weightGrams / 1_000) * ratePerKg
        return addsExtra ? base * (1 + CostRates.materialExtraRate) : base
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
    /// Cost of one piece, in Rupiah or converted from RMB.
    var unitPrice: PriceInput
    var pcsPerCarton: Double
    var cubicMetres: Double
    var ratePerCubicMetre: Double
    /// Scales the total up, then back down. Both sit at 1 when the total is
    /// to be left alone, and anything at or below zero is read as 1 rather
    /// than costing the item at nothing.
    var multiplier: Double = 1
    var divider: Double = 1

    /// What the piece itself costs.
    var productCost: Double {
        unitPrice.value
    }

    /// The piece's share of the carton's freight.
    var importCost: Double {
        guard pcsPerCarton > 0 else { return 0 }
        return cubicMetres * ratePerCubicMetre / pcsPerCarton
    }

    /// The piece and its freight, before scaling.
    var totalCost: Double {
        productCost + importCost
    }

    /// What the item is actually costed at, once scaled.
    var finalTotalCost: Double {
        let up = multiplier > 0 ? multiplier : 1
        let down = divider > 0 ? divider : 1
        return totalCost * up / down
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
        costPerDay: Double,
        materialPrice: PriceInput,
        addsExtra: Bool
    )
    /// Unit cost plus the carton's share of freight. IMPORT, of any kind.
    case cartoned(
        unitPrice: PriceInput,
        pcsPerCarton: Double,
        cubicMetres: Double,
        ratePerCubicMetre: Double,
        multiplier: Double,
        divider: Double,
        kind: ImportKind
    )
    /// A table's cost spread over the pieces it holds. UV.
    case perTable(costPerTable: Double, pcsPerTable: Double)
    /// A carton's packing cost spread over the pieces in it, with a note of
    /// what that cost covers. PACKAGING LABOUR COST.
    case perCarton(costPerCarton: Double, pcsPerCarton: Double, note: String)
    /// Something bought locally, at a figure entered directly.
    /// PURCHASE LOCAL.
    case localPurchase(amount: Double, kind: LocalPurchaseKind)
    /// A figure entered directly. SPRAY, PAD PRINT and both labour costs.
    case flat(amount: Double)

    /// Cost of one piece, in Rupiah.
    var subtotal: Double {
        switch self {
        case let .injection(weightGrams, cycleTimeSeconds, cavities, material, costPerDay, materialPrice, addsExtra):
            return InjectionBreakdown(
                weightGrams: weightGrams,
                cycleTimeSeconds: cycleTimeSeconds,
                cavities: cavities,
                material: material,
                costPerDay: costPerDay,
                materialPrice: materialPrice,
                addsExtra: addsExtra
            ).totalPartCost

        case let .cartoned(unitPrice, pcsPerCarton, cubicMetres, ratePerCubicMetre, multiplier, divider, _):
            return CartonBreakdown(
                unitPrice: unitPrice,
                pcsPerCarton: pcsPerCarton,
                cubicMetres: cubicMetres,
                ratePerCubicMetre: ratePerCubicMetre,
                multiplier: multiplier,
                divider: divider
            ).finalTotalCost

        case let .perTable(costPerTable, pcsPerTable):
            guard pcsPerTable > 0 else { return 0 }
            return costPerTable / pcsPerTable

        case let .perCarton(costPerCarton, pcsPerCarton, _):
            guard pcsPerCarton > 0 else { return 0 }
            return costPerCarton / pcsPerCarton

        case let .localPurchase(amount, _):
            return amount

        case let .flat(amount):
            return amount
        }
    }

    /// Short description of the inputs, shown under the item name.
    var summary: String {
        switch self {
        case let .injection(weightGrams, cycleTimeSeconds, cavities, material, costPerDay, _, addsExtra):
            let extra = addsExtra ? " +3%" : ""
            return "\(weightGrams.compact) g \(material.rawValue)\(extra) · \(cycleTimeSeconds.compact) s · \(cavities.compact) cav · \(costPerDay.rupiah)/day"
        case let .cartoned(unitPrice, pcsPerCarton, cubicMetres, ratePerCubicMetre, multiplier, divider, _):
            let carton = "\(unitPrice.value.rupiah)/pc\(unitPrice.origin) · \(pcsPerCarton.compact) pcs/ctn · \(cubicMetres.compact) m³ · \(ratePerCubicMetre.rupiah)/m³"
            // Only worth saying when it actually changes the figure.
            guard multiplier != 1 || divider != 1 else { return carton }
            return carton + " · ×\(multiplier.compact) ÷\(divider.compact)"
        case let .perTable(costPerTable, pcsPerTable):
            return "\(costPerTable.rupiah)/table · \(pcsPerTable.compact) pcs/table"
        case let .perCarton(costPerCarton, pcsPerCarton, note):
            let packing = "\(costPerCarton.rupiah)/ctn · \(pcsPerCarton.compact) pcs/ctn"
            let trimmed = note.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? packing : "\(packing) · \(trimmed)"
        case let .localPurchase(_, kind):
            return kind.rawValue
        case .flat:
            return ""
        }
    }
}

struct CostItem: Identifiable, Codable, Hashable {
    let id: UUID
    var category: CostCategory
    var name: String
    var details: CostDetails

    var subtotal: Double { details.subtotal }

    /// What an imported item is, when it is one.
    var importKind: ImportKind? {
        if case let .cartoned(_, _, _, _, _, _, kind) = details { return kind }
        return nil
    }

    /// The heading this item is listed under. Imports keep their kind visible
    /// so a sparepart is never confused with packaging in the totals.
    var groupTitle: String {
        guard let importKind else { return category.rawValue }
        return "\(category.rawValue) · \(importKind.rawValue)"
    }

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
    /// Reads a number as it was typed. A separator that repeats is grouping,
    /// so "3.500.000" is three and a half million; a single one is a decimal
    /// point, so "1,5" and "1.5" both read as 1.5.
    init?(costingInput text: String) {
        var cleaned = text.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }

        for separator in [".", ","] where cleaned.components(separatedBy: separator).count > 2 {
            cleaned = cleaned.replacingOccurrences(of: separator, with: "")
        }
        cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(cleaned) else { return nil }
        self = value
    }

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

    /// A fraction as a percentage: 0.2 reads as 20%.
    var percent: String {
        formatted(.percent.precision(.fractionLength(0...1)))
    }

    /// Digits only, for prefilling a field. Grouping separators are left out
    /// because "3.500.000" does not read back as a number.
    var plainDigits: String {
        formatted(.number.precision(.fractionLength(0...2)).grouping(.never))
    }
}

//
//  SavedProduct.swift
//  Costing Calculator
//

import Foundation

/// A finished costing: every item that was saved into it, kept together under
/// one name. Saving an item is the first save; saving the grand total is the
/// second, and produces one of these.
struct SavedProduct: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var items: [CostItem]
    var savedAt: Date
    /// Whether the 7.5% lain-lain is added on top.
    var includesMiscellaneous: Bool
    /// Divides the grand total to give a selling price. Nil until one is set.
    var sellingDivider: Double?
    /// Name of the product's photo in ProductImageStore, if one was added.
    var imageFileName: String?

    init(
        id: UUID = UUID(),
        name: String,
        items: [CostItem],
        savedAt: Date = .now,
        includesMiscellaneous: Bool = true,
        sellingDivider: Double? = nil,
        imageFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.savedAt = savedAt
        self.includesMiscellaneous = includesMiscellaneous
        self.sellingDivider = sellingDivider
        self.imageFileName = imageFileName
    }

    var subtotal: Double { items.subtotal }

    var miscellaneous: Double {
        includesMiscellaneous ? subtotal * CostRates.miscellaneousRate : 0
    }

    var grandTotal: Double { subtotal + miscellaneous }

    /// What the costing sells for, once a divider is set. Dividing by 0.8
    /// leaves a fifth of the price over as margin.
    var sellingPrice: Double? {
        guard let sellingDivider, sellingDivider > 0 else { return nil }
        return grandTotal / sellingDivider
    }

    /// The share of the selling price that is not cost, as a fraction.
    var margin: Double? {
        guard let sellingPrice, sellingPrice > 0 else { return nil }
        return (sellingPrice - grandTotal) / sellingPrice
    }
}

extension Array where Element == CostItem {
    /// Everything entered by hand, before Miscellaneous.
    var subtotal: Double {
        reduce(0) { $0 + $1.subtotal }
    }

    /// Headings that actually have items, in category order. Imports are split
    /// out by kind so each stays identifiable in the totals.
    var groupTitles: [String] {
        CostCategory.allCases.flatMap { category -> [String] in
            guard category == .importItem else {
                return contains { $0.category == category } ? [category.rawValue] : []
            }
            return ImportKind.allCases.compactMap { kind in
                let title = "\(category.rawValue) · \(kind.rawValue)"
                return contains { $0.groupTitle == title } ? title : nil
            }
        }
    }

    /// The items listed under one heading.
    func inGroup(_ title: String) -> [CostItem] {
        filter { $0.groupTitle == title }
    }
}

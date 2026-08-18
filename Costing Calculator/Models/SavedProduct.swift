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

    init(id: UUID = UUID(), name: String, items: [CostItem], savedAt: Date = .now) {
        self.id = id
        self.name = name
        self.items = items
        self.savedAt = savedAt
    }

    var subtotal: Double { items.subtotal }
    var miscellaneous: Double { subtotal * CostRates.miscellaneousRate }
    var grandTotal: Double { subtotal + miscellaneous }
}

extension Array where Element == CostItem {
    /// Everything entered by hand, before Miscellaneous.
    var subtotal: Double {
        reduce(0) { $0 + $1.subtotal }
    }

    /// Categories that actually have items, in the order they are listed.
    var categoriesInUse: [CostCategory] {
        CostCategory.allCases.filter { category in
            contains { $0.category == category }
        }
    }
}

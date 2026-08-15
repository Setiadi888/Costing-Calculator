//
//  CostItem.swift
//  Costing Calculator
//

import Foundation

struct CostItem: Identifiable, Codable {
    let id: UUID
    var category: CostCategory
    var name: String
    var unitCost: Double
    var quantity: Double

    var total: Double { unitCost * quantity }

    init(id: UUID = UUID(), category: CostCategory, name: String, unitCost: Double, quantity: Double) {
        self.id = id
        self.category = category
        self.name = name
        self.unitCost = unitCost
        self.quantity = quantity
    }
}

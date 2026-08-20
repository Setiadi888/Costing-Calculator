//
//  ItemRoutes.swift
//  Costing Calculator
//

import Foundation

/// Where an item being added or edited belongs.
enum ItemTarget: Hashable {
    /// The working list on the home page, not yet saved as a product.
    case draft
    /// A product that has already been saved.
    case product(UUID)
}

/// Pick a category for a new item.
struct ChooseCategoryRoute: Hashable {
    let target: ItemTarget
}

/// Price a finished costing.
struct SellingPriceRoute: Hashable {
    let productID: UUID
}

/// Fill in an item. `itemID` is nil when adding, set when editing.
struct ItemFormRoute: Hashable {
    let target: ItemTarget
    let category: CostCategory
    let itemID: UUID?
}

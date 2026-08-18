//
//  CategorySelectionView.swift
//  Costing Calculator
//

import SwiftUI

struct CategorySelectionView: View {
    /// Carried through so the finished item lands in the right place.
    let target: ItemTarget

    var body: some View {
        List(CostCategory.allCases) { category in
            NavigationLink(
                category.rawValue,
                value: ItemFormRoute(target: target, category: category, itemID: nil)
            )
        }
        .navigationTitle("Select Category")
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView(target: .draft)
    }
}

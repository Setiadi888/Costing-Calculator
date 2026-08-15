//
//  CategorySelectionView.swift
//  Costing Calculator
//

import SwiftUI

struct CategorySelectionView: View {
    var body: some View {
        List(CostCategory.allCases) { category in
            NavigationLink(category.rawValue, value: category)
        }
        .navigationTitle("Select Category")
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView()
    }
}

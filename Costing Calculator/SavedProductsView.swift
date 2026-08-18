//
//  SavedProductsView.swift
//  Costing Calculator
//

import SwiftUI

/// Every costing that has been saved from the grand total.
struct SavedProductsView: View {
    let products: [SavedProduct]

    var body: some View {
        List {
            if products.isEmpty {
                ContentUnavailableView(
                    "No Saved Products",
                    systemImage: "tray",
                    description: Text("Save a grand total to keep a costing here.")
                )
            } else {
                ForEach(products) { product in
                    NavigationLink(value: product) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                Text("\(product.items.count) item\(product.items.count == 1 ? "" : "s") · \(product.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(product.grandTotal.rupiah)
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Products")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: FinalTotalRoute()) {
                    Label("Final Total", systemImage: "sum")
                }
                .disabled(products.isEmpty)
            }
        }
    }
}

/// The full breakdown of one saved costing.
struct SavedProductDetailView: View {
    let product: SavedProduct

    var body: some View {
        List {
            ForEach(product.items.categoriesInUse) { category in
                Section(category.rawValue) {
                    ForEach(product.items.filter { $0.category == category }) { item in
                        CostItemRow(item: item)
                    }
                }
            }

            Section("Summary") {
                CostSummaryRows(
                    subtotal: product.subtotal,
                    miscellaneous: product.miscellaneous,
                    grandTotal: product.grandTotal
                )
            }
        }
        .navigationTitle(product.name)
    }
}

/// One costed item: its name, the inputs behind it, and what it comes to.
struct CostItemRow: View {
    let item: CostItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                if !item.details.summary.isEmpty {
                    Text(item.details.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(item.subtotal.rupiah)
        }
    }
}

/// Sub total, Miscellaneous and Grand Total, shown the same way everywhere.
struct CostSummaryRows: View {
    let subtotal: Double
    let miscellaneous: Double
    let grandTotal: Double

    var body: some View {
        row("Sub Total", subtotal)
        row("Miscellaneous (7.5%)", miscellaneous)
        row("Grand Total", grandTotal, emphasised: true)
    }

    private func row(_ title: String, _ value: Double, emphasised: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.rupiah)
        }
        .font(emphasised ? .headline : .body)
    }
}

#Preview {
    NavigationStack {
        SavedProductsView(products: [
            SavedProduct(
                name: "Product 1",
                items: [
                    CostItem(
                        category: .injectionPart,
                        name: "Housing",
                        details: .injection(
                            weightGrams: 50,
                            cycleTimeSeconds: 20,
                            cavities: 10,
                            material: .pp,
                            costPerDay: 1_500_000
                        )
                    )
                ]
            )
        ])
    }
}

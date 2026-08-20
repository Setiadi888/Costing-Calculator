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
                    NavigationLink(value: product.id) {
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

/// The full breakdown of one saved costing, still open to changes.
struct SavedProductDetailView: View {
    @Binding var product: SavedProduct

    var body: some View {
        List {
            Section("Name") {
                TextField("Name", text: $product.name)
                    .labelsHidden()
            }

            ForEach(product.items.groupTitles, id: \.self) { title in
                Section(title) {
                    ForEach(product.items.inGroup(title)) { item in
                        NavigationLink(
                            value: ItemFormRoute(
                                target: .product(product.id),
                                category: item.category,
                                itemID: item.id
                            )
                        ) {
                            CostItemRow(item: item)
                        }
                    }
                    .onDelete { delete(group: title, at: $0) }
                }
            }

            Section("Summary") {
                Toggle("Add Lain-lain (7.5%)", isOn: $product.includesMiscellaneous)
                CostSummaryRows(
                    subtotal: product.subtotal,
                    miscellaneous: product.miscellaneous,
                    grandTotal: product.grandTotal,
                    includesMiscellaneous: product.includesMiscellaneous
                )
            }
        }
        .navigationTitle(product.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(
                    value: ChooseCategoryRoute(target: .product(product.id))
                ) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
    }

    private func delete(group title: String, at offsets: IndexSet) {
        let itemsInGroup = product.items.inGroup(title)
        let idsToDelete = Set(offsets.map { itemsInGroup[$0].id })
        product.items.removeAll { idsToDelete.contains($0.id) }
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
    /// Dims the lain-lain line when it is switched off.
    var includesMiscellaneous = true

    var body: some View {
        row("Sub Total", subtotal)
        row("Lain-lain (7.5%)", miscellaneous)
            .foregroundStyle(includesMiscellaneous ? .primary : .secondary)
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
                            costPerDay: 1_500_000,
                            materialPrice: PriceInput(rupiah: 28_000),
                            addsExtra: false
                        )
                    )
                ]
            )
        ])
    }
}

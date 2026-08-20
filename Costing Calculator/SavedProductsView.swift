//
//  SavedProductsView.swift
//  Costing Calculator
//

import SwiftUI

/// What the saved costings are ordered on.
enum ProductSortField: String, CaseIterable, Identifiable {
    case dateSaved = "Date Saved"
    case cost = "Cost"
    case sellingPrice = "Selling Price"
    case margin = "Margin"

    var id: String { rawValue }
}

/// Which end of that they are ordered from. Named ProductSortOrder rather
/// than SortOrder, which Foundation already has.
enum ProductSortOrder: String, CaseIterable, Identifiable {
    case highestFirst
    case lowestFirst

    var id: String { rawValue }

    /// Dates do not read as high and low.
    func label(for field: ProductSortField) -> String {
        switch (self, field) {
        case (.highestFirst, .dateSaved): return "Newest First"
        case (.lowestFirst, .dateSaved): return "Oldest First"
        case (.highestFirst, _): return "Highest First"
        case (.lowestFirst, _): return "Lowest First"
        }
    }
}

/// Every costing that has been saved from the grand total.
struct SavedProductsView: View {
    @Binding var products: [SavedProduct]

    @State private var field: ProductSortField = .dateSaved
    /// Oldest first, so the list opens in the order things were saved.
    @State private var order: ProductSortOrder = .lowestFirst
    @State private var query = ""

    /// The costings on screen: what the search matches, in the chosen order.
    private var visible: [SavedProduct] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let matched = trimmed.isEmpty
            ? products
            : products.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }

        return matched.sorted { left, right in
            switch (sortKey(left), sortKey(right)) {
            case let (lhs?, rhs?):
                return order == .highestFirst ? lhs > rhs : lhs < rhs
            // A costing with nothing to compare stays at the bottom either
            // way round, rather than heading the list the moment the order
            // is flipped.
            case (nil, _?): return false
            case (_?, nil): return true
            case (nil, nil): return false
            }
        }
    }

    /// What the chosen field sorts on, or nil where a costing has no such
    /// figure — no selling price set means no price and no margin.
    private func sortKey(_ product: SavedProduct) -> Double? {
        switch field {
        case .dateSaved: return product.savedAt.timeIntervalSince1970
        case .cost: return product.grandTotal
        case .sellingPrice: return product.sellingPrice
        case .margin: return product.margin
        }
    }

    var body: some View {
        List {
            if products.isEmpty {
                ContentUnavailableView(
                    "No Saved Products",
                    systemImage: "tray",
                    description: Text("Save a grand total to keep a costing here.")
                )
            } else if visible.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(visible) { product in
                    // Bind back into the array itself, so a photo added to a
                    // row lands on the costing and not on a copy of it.
                    if let index = products.firstIndex(where: { $0.id == product.id }) {
                        row($products[index])
                    }
                }
            }
        }
        .navigationTitle("Saved Products")
        .searchable(text: $query, prompt: "Name or code")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort By", selection: $field) {
                        ForEach(ProductSortField.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    Picker("Order", selection: $order) {
                        ForEach(ProductSortOrder.allCases) { option in
                            Text(option.label(for: field)).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .disabled(products.isEmpty)
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: FinalTotalRoute()) {
                    Label("Final Total", systemImage: "sum")
                }
                .disabled(products.isEmpty)
            }
        }
    }

    private func row(_ binding: Binding<SavedProduct>) -> some View {
        let product = binding.wrappedValue
        return HStack(spacing: 10) {
            ProductThumbnail(product: binding)
            NavigationLink(value: product.id) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.name)
                        Text("\(product.items.count) item\(product.items.count == 1 ? "" : "s") · \(product.savedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let price = product.sellingPrice, let margin = product.margin {
                            Text("Sells at \(price.rupiah) · margin \(margin.percent)")
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                    }
                    Spacer()
                    Text(product.grandTotal.rupiah)
                        .font(.headline)
                }
            }
            // Its own link rather than a button, so the row's link does not
            // swallow the tap.
            NavigationLink(value: SellingPriceRoute(productID: product.id)) {
                Text("+Selling Price")
                    .font(.caption)
                    .fixedSize()
            }
            .buttonStyle(.borderless)
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
        SavedProductsView(products: .constant([
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
        ]))
    }
}

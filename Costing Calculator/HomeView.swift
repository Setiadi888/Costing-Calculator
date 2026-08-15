//
//  HomeView.swift
//  Costing Calculator
//

import SwiftUI

private struct AddItemRoute: Hashable {}

struct HomeView: View {
    @State private var items: [CostItem] = []
    @State private var path = NavigationPath()

    /// Everything entered by hand, before Miscellaneous.
    private var subtotal: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }

    /// Added on top of every other cost.
    private var miscellaneous: Double {
        subtotal * CostRates.miscellaneousRate
    }

    private var grandTotal: Double {
        subtotal + miscellaneous
    }

    private var categoriesInUse: [CostCategory] {
        CostCategory.allCases.filter { category in items.contains { $0.category == category } }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Items Yet",
                        systemImage: "shippingbox",
                        description: Text("Tap + to add a costing item.")
                    )
                } else {
                    ForEach(categoriesInUse) { category in
                        Section(category.rawValue) {
                            ForEach(items.filter { $0.category == category }) { item in
                                itemRow(item)
                            }
                            .onDelete { delete(category: category, at: $0) }
                        }
                    }

                    Section("Summary") {
                        summaryRow("Sub Total", subtotal)
                        summaryRow("Miscellaneous (7.5%)", miscellaneous)
                        summaryRow("Grand Total", grandTotal, emphasised: true)
                    }
                }
            }
            .navigationTitle("Costing Calculator")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        path.append(AddItemRoute())
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: AddItemRoute.self) { _ in
                CategorySelectionView()
            }
            .navigationDestination(for: CostCategory.self) { category in
                AddCostItemView(category: category) { item in
                    items.append(item)
                    path = NavigationPath()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !items.isEmpty {
                    HStack {
                        Text("Grand Total")
                            .font(.headline)
                        Spacer()
                        Text(grandTotal.rupiah)
                            .font(.headline)
                    }
                    .padding()
                    .background(.bar)
                }
            }
        }
    }

    private func itemRow(_ item: CostItem) -> some View {
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

    private func summaryRow(_ title: String, _ value: Double, emphasised: Bool = false) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value.rupiah)
        }
        .font(emphasised ? .headline : .body)
    }

    private func delete(category: CostCategory, at offsets: IndexSet) {
        let itemsInCategory = items.filter { $0.category == category }
        let idsToDelete = Set(offsets.map { itemsInCategory[$0].id })
        items.removeAll { idsToDelete.contains($0.id) }
    }
}

#Preview {
    HomeView()
}

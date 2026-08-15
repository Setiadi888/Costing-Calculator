//
//  HomeView.swift
//  Costing Calculator
//

import SwiftUI

private struct AddItemRoute: Hashable {}

struct HomeView: View {
    @State private var items: [CostItem] = []
    @State private var path = NavigationPath()

    private var grandTotal: Double {
        items.reduce(0) { $0 + $1.total }
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
                        Text(grandTotal, format: .number.precision(.fractionLength(2)))
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
            VStack(alignment: .leading) {
                Text(item.name)
                Text("\(item.quantity.formatted()) x \(item.unitCost.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.total, format: .number.precision(.fractionLength(2)))
        }
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

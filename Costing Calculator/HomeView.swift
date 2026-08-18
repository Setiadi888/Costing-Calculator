//
//  HomeView.swift
//  Costing Calculator
//

import SwiftUI

private struct AddItemRoute: Hashable {}
private struct SavedProductsRoute: Hashable {}

struct HomeView: View {
    /// Items saved into the costing being worked on. This is the first save.
    @State private var items: [CostItem] = []
    /// Costings finished off by saving their grand total. The second save.
    @State private var savedProducts: [SavedProduct] = []

    @State private var path = NavigationPath()
    @State private var isNamingProduct = false
    @State private var draftName = ""

    private var subtotal: Double { items.subtotal }
    private var miscellaneous: Double { subtotal * CostRates.miscellaneousRate }
    private var grandTotal: Double { subtotal + miscellaneous }

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
                    ForEach(items.categoriesInUse) { category in
                        Section(category.rawValue) {
                            ForEach(items.filter { $0.category == category }) { item in
                                CostItemRow(item: item)
                            }
                            .onDelete { delete(category: category, at: $0) }
                        }
                    }

                    Section("Summary") {
                        CostSummaryRows(
                            subtotal: subtotal,
                            miscellaneous: miscellaneous,
                            grandTotal: grandTotal
                        )
                    }
                }
            }
            .navigationTitle("Costing Calculator")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        path.append(SavedProductsRoute())
                    } label: {
                        Label("Saved Products", systemImage: "tray.full")
                    }
                }
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
            .navigationDestination(for: SavedProductsRoute.self) { _ in
                SavedProductsView(products: savedProducts)
            }
            .navigationDestination(for: SavedProduct.self) { product in
                SavedProductDetailView(product: product)
            }
            .navigationDestination(for: FinalTotalRoute.self) { _ in
                FinalTotalView(products: savedProducts)
            }
            .safeAreaInset(edge: .bottom) {
                if !items.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Grand Total")
                                .font(.headline)
                            Text(grandTotal.rupiah)
                                .font(.headline)
                        }
                        Spacer()
                        Button("Save Product") {
                            draftName = "Product \(savedProducts.count + 1)"
                            isNamingProduct = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.bar)
                }
            }
            .alert("Save Product", isPresented: $isNamingProduct) {
                TextField("Product name", text: $draftName)
                Button("Cancel", role: .cancel) {}
                Button("Save") { saveProduct() }
            } message: {
                Text("Grand total \(grandTotal.rupiah)")
            }
        }
    }

    /// Finishes the costing off: keeps it as a saved product, clears the
    /// working list, and shows where it went.
    private func saveProduct() {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        let product = SavedProduct(
            name: trimmed.isEmpty ? "Product \(savedProducts.count + 1)" : trimmed,
            items: items
        )
        savedProducts.append(product)
        items.removeAll()
        path = NavigationPath()
        path.append(SavedProductsRoute())
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

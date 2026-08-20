//
//  HomeView.swift
//  Costing Calculator
//

import SwiftUI

private struct SavedProductsRoute: Hashable {}

struct HomeView: View {
    /// Items saved into the costing being worked on. This is the first save.
    @State private var items: [CostItem] = []
    /// Costings finished off by saving their grand total. The second save.
    @State private var savedProducts: [SavedProduct] = []

    @State private var path = NavigationPath()
    @State private var isNamingProduct = false
    @State private var draftName = ""

    /// Whether the 7.5% lain-lain is added to the costing being worked on.
    @State private var includesMiscellaneous = true

    /// Stops an empty state being written over good data before the saved
    /// state has been read back in.
    @State private var hasLoaded = false

    private var subtotal: Double { items.subtotal }

    private var miscellaneous: Double {
        includesMiscellaneous ? subtotal * CostRates.miscellaneousRate : 0
    }

    private var grandTotal: Double { subtotal + miscellaneous }

    /// Everything worth keeping, gathered so one change watcher covers it all.
    private var state: CostingState {
        CostingState(
            items: items,
            savedProducts: savedProducts,
            includesMiscellaneous: includesMiscellaneous
        )
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
                    ForEach(items.groupTitles, id: \.self) { title in
                        Section(title) {
                            ForEach(items.inGroup(title)) { item in
                                NavigationLink(
                                    value: ItemFormRoute(
                                        target: .draft,
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
                        Toggle("Add Lain-lain (7.5%)", isOn: $includesMiscellaneous)
                        CostSummaryRows(
                            subtotal: subtotal,
                            miscellaneous: miscellaneous,
                            grandTotal: grandTotal,
                            includesMiscellaneous: includesMiscellaneous
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
                        path.append(ChooseCategoryRoute(target: .draft))
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: ChooseCategoryRoute.self) { route in
                CategorySelectionView(target: route.target)
            }
            .navigationDestination(for: ItemFormRoute.self) { route in
                AddCostItemView(
                    category: route.category,
                    existing: item(for: route)
                ) { item in
                    apply(item, route: route)
                }
            }
            .navigationDestination(for: SavedProductsRoute.self) { _ in
                SavedProductsView(products: savedProducts)
            }
            .navigationDestination(for: SavedProduct.ID.self) { id in
                if let index = savedProducts.firstIndex(where: { $0.id == id }) {
                    SavedProductDetailView(product: $savedProducts[index])
                }
            }
            .navigationDestination(for: SellingPriceRoute.self) { route in
                if let index = savedProducts.firstIndex(where: { $0.id == route.productID }) {
                    SellingPriceView(product: $savedProducts[index])
                }
            }
            .navigationDestination(for: FinalTotalRoute.self) { _ in
                FinalTotalView(products: savedProducts)
            }
            .task {
                guard !hasLoaded else { return }
                let saved = CostingStore.load()
                items = saved.items
                savedProducts = saved.savedProducts
                includesMiscellaneous = saved.includesMiscellaneous
                hasLoaded = true
            }
            .onChange(of: state) { _, newState in
                guard hasLoaded else { return }
                CostingStore.save(newState)
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

    /// The item a form is editing, or nil when the form is adding a new one.
    private func item(for route: ItemFormRoute) -> CostItem? {
        guard let itemID = route.itemID else { return nil }
        switch route.target {
        case .draft:
            return items.first { $0.id == itemID }
        case let .product(productID):
            return savedProducts
                .first { $0.id == productID }?
                .items.first { $0.id == itemID }
        }
    }

    /// Puts a finished item where it belongs, replacing the old one when
    /// editing, then steps back to the list it came from.
    private func apply(_ item: CostItem, route: ItemFormRoute) {
        switch route.target {
        case .draft:
            store(item, in: &items)
        case let .product(productID):
            if let index = savedProducts.firstIndex(where: { $0.id == productID }) {
                store(item, in: &savedProducts[index].items)
            }
        }

        // Adding pushed a category picker as well as the form; editing only
        // pushed the form.
        let pushed = route.itemID == nil ? 2 : 1
        path.removeLast(min(pushed, path.count))
    }

    private func store(_ item: CostItem, in list: inout [CostItem]) {
        if let index = list.firstIndex(where: { $0.id == item.id }) {
            list[index] = item
        } else {
            list.append(item)
        }
    }

    /// Finishes the costing off: keeps it as a saved product, clears the
    /// working list, and shows where it went.
    private func saveProduct() {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        let product = SavedProduct(
            name: trimmed.isEmpty ? "Product \(savedProducts.count + 1)" : trimmed,
            items: items,
            includesMiscellaneous: includesMiscellaneous
        )
        savedProducts.append(product)
        items.removeAll()
        includesMiscellaneous = true
        path = NavigationPath()
        path.append(SavedProductsRoute())
    }

    private func delete(group title: String, at offsets: IndexSet) {
        let itemsInGroup = items.inGroup(title)
        let idsToDelete = Set(offsets.map { itemsInGroup[$0].id })
        items.removeAll { idsToDelete.contains($0.id) }
    }
}

#Preview {
    HomeView()
}

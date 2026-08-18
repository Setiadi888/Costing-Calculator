//
//  FinalTotalView.swift
//  Costing Calculator
//

import SwiftUI

struct FinalTotalRoute: Hashable {}

/// Every finalised costing added together. This works at the level of whole
/// products — each line is one saved grand total, not an item or a part.
struct FinalTotalView: View {
    let products: [SavedProduct]

    private var subtotal: Double {
        products.reduce(0) { $0 + $1.subtotal }
    }

    private var miscellaneous: Double {
        products.reduce(0) { $0 + $1.miscellaneous }
    }

    private var finalTotal: Double {
        products.reduce(0) { $0 + $1.grandTotal }
    }

    var body: some View {
        List {
            if products.isEmpty {
                ContentUnavailableView(
                    "Nothing Finalised Yet",
                    systemImage: "sum",
                    description: Text("Save a grand total and it will be counted here.")
                )
            } else {
                Section("Products") {
                    ForEach(products) { product in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                Text("\(product.items.count) item\(product.items.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(product.grandTotal.rupiah)
                        }
                    }
                }

                Section("Final Total") {
                    CostSummaryRows(
                        subtotal: subtotal,
                        miscellaneous: miscellaneous,
                        grandTotal: finalTotal
                    )
                }
            }
        }
        .navigationTitle("Final Total")
        .safeAreaInset(edge: .bottom) {
            if !products.isEmpty {
                HStack {
                    Text("\(products.count) product\(products.count == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(finalTotal.rupiah)
                        .font(.headline)
                }
                .padding()
                .background(.bar)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FinalTotalView(products: [
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
                            materialPrice: PriceInput(rupiah: 28_000)
                        )
                    )
                ]
            ),
            SavedProduct(
                name: "Product 2",
                items: [
                    CostItem(category: .spray, name: "Spray", details: .flat(amount: 2_500))
                ]
            )
        ])
    }
}

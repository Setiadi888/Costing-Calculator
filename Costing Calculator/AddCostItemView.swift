//
//  AddCostItemView.swift
//  Costing Calculator
//

import SwiftUI

struct AddCostItemView: View {
    let category: CostCategory
    let onSave: (CostItem) -> Void

    @State private var name = ""
    @State private var unitCost = ""
    @State private var quantity = "1"

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(unitCost) != nil
            && Double(quantity) != nil
    }

    var body: some View {
        Form {
            Section("Item Details") {
                TextField("Item Name", text: $name)
                TextField("Unit Cost", text: $unitCost)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                TextField("Quantity", text: $quantity)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
        }
        .navigationTitle(category.rawValue)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    guard let cost = Double(unitCost), let qty = Double(quantity) else { return }
                    onSave(CostItem(category: category, name: name, unitCost: cost, quantity: qty))
                }
                .disabled(!isValid)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddCostItemView(category: .injectionPart) { _ in }
    }
}

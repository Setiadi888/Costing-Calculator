//
//  AddCostItemView.swift
//  Costing Calculator
//

import SwiftUI

struct AddCostItemView: View {
    let category: CostCategory
    let onSave: (CostItem) -> Void

    @State private var name = ""

    // INJECTION PART
    @State private var weightGrams = ""
    @State private var cycleTime = ""
    @State private var cavities = "1"
    @State private var material: MouldingMaterial = .pp

    // SPAREPART / PACKAGING
    @State private var unitCost = ""
    @State private var pcsPerCarton = ""
    @State private var cubicMetres = ""

    // UV
    @State private var costPerTable = ""
    @State private var pcsPerTable = ""

    // SPRAY / PAD PRINT / LABOUR
    @State private var amount = ""

    var body: some View {
        Form {
            Section("Name") {
                TextField(category.rawValue.capitalized, text: $name)
            }

            switch category {
            case .injectionPart: injectionFields
            case .sparePart, .packaging: cartonFields
            case .uv: uvFields
            case .spray, .padPrint, .packagingLabourCost, .assemblyLabourCost: flatField
            }

            Section("Sub Total") {
                HStack {
                    Text("Cost per pc")
                    Spacer()
                    Text(details?.subtotal.rupiah ?? "—")
                        .font(.headline)
                        .foregroundStyle(details == nil ? .secondary : .primary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(category.rawValue)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    guard let details else { return }
                    onSave(CostItem(category: category, name: name, details: details))
                }
                .disabled(details == nil)
            }
        }
    }

    // MARK: - Category fields

    private var injectionFields: some View {
        Group {
            Section("Material") {
                numberField("Weight (gram)", text: $weightGrams)
                Picker("Type of Material", selection: $material) {
                    ForEach(MouldingMaterial.allCases) { material in
                        Text("\(material.rawValue) — \(material.ratePerKg.rupiah)/kg").tag(material)
                    }
                }
            }
            Section {
                numberField("Cycle Time (seconds)", text: $cycleTime)
                numberField("Number of Cavities", text: $cavities)
            } header: {
                Text("Cycle Time")
            } footer: {
                Text("Injection runs at \(CostRates.injectionPerDay.rupiah)/day over \(CostRates.secondsPerDay.compact) seconds.")
            }
        }
    }

    private var cartonFields: some View {
        Section {
            numberField("Cost of Product (Rp) / pcs", text: $unitCost)
            numberField("Total pcs / Carton", text: $pcsPerCarton)
            numberField("Total m³ for Carton", text: $cubicMetres)
        } header: {
            Text("Carton")
        } footer: {
            Text("Freight is \(CostRates.freightPerCubicMetre.rupiah) per m³, split across the carton.")
        }
    }

    private var uvFields: some View {
        Section("Table") {
            numberField("Total Cost / Table (Rp)", text: $costPerTable)
            numberField("Total pcs / Table", text: $pcsPerTable)
        }
    }

    private var flatField: some View {
        Section("Cost") {
            numberField("Estimated \(category.rawValue.capitalized) (Rp)", text: $amount)
        }
    }

    private func numberField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            #if os(iOS)
            .keyboardType(.decimalPad)
            #endif
    }

    // MARK: - Input

    /// Valid inputs for this category, or nil while anything is missing.
    private var details: CostDetails? {
        switch category {
        case .injectionPart:
            guard let weight = parse(weightGrams),
                  let cycle = parse(cycleTime),
                  let cavityCount = parse(cavities), cavityCount > 0
            else { return nil }
            return .injection(
                weightGrams: weight,
                cycleTimeSeconds: cycle,
                cavities: cavityCount,
                material: material
            )

        case .sparePart, .packaging:
            guard let cost = parse(unitCost),
                  let pcs = parse(pcsPerCarton), pcs > 0,
                  let volume = parse(cubicMetres)
            else { return nil }
            return .cartoned(unitCost: cost, pcsPerCarton: pcs, cubicMetres: volume)

        case .uv:
            guard let cost = parse(costPerTable),
                  let pcs = parse(pcsPerTable), pcs > 0
            else { return nil }
            return .perTable(costPerTable: cost, pcsPerTable: pcs)

        case .spray, .padPrint, .packagingLabourCost, .assemblyLabourCost:
            guard let value = parse(amount) else { return nil }
            return .flat(amount: value)
        }
    }

    /// Accepts either separator, so "1,5" and "1.5" both read as 1.5.
    private func parse(_ text: String) -> Double? {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        return cleaned.isEmpty ? nil : Double(cleaned)
    }
}

#Preview("Injection") {
    NavigationStack {
        AddCostItemView(category: .injectionPart) { _ in }
    }
}

#Preview("Spray") {
    NavigationStack {
        AddCostItemView(category: .spray) { _ in }
    }
}

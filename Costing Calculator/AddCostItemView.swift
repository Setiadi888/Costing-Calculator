//
//  AddCostItemView.swift
//  Costing Calculator
//

import SwiftUI

struct AddCostItemView: View {
    let category: CostCategory
    let onSave: (CostItem) -> Void

    @State private var name: String

    init(category: CostCategory, onSave: @escaping (CostItem) -> Void) {
        self.category = category
        self.onSave = onSave
        // Start from the category name so the field holds real text to edit,
        // rather than a label beside an empty box.
        _name = State(initialValue: category.rawValue.capitalized)
    }

    // INJECTION PART
    @State private var weightGrams = ""
    @State private var cycleTime = ""
    @State private var cavities = "1"
    @State private var material: MouldingMaterial = .pp
    @State private var costPerDay = CostRates.defaultInjectionPerDay

    // SPAREPART / PACKAGING
    @State private var unitCost = ""
    @State private var pcsPerCarton = ""
    @State private var cubicMetres = ""
    @State private var ratePerCubicMetre = CostRates.defaultFreightPerCubicMetre.compact

    // UV
    @State private var costPerTable = ""
    @State private var pcsPerTable = ""

    // SPRAY / PAD PRINT / LABOUR
    @State private var amount = ""

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name)
                    .labelsHidden()
            }

            switch category {
            case .injectionPart: injectionFields
            case .sparePart, .packaging: cartonFields
            case .uv: uvFields
            case .spray, .padPrint, .packagingLabourCost, .assemblyLabourCost: flatField
            }

            Section(totalTitle) {
                totalRow(totalTitle, value: details?.subtotal)
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

    /// Categories split into sections total those sections up; the rest just
    /// show the one figure they were given.
    private var totalTitle: String {
        switch category {
        case .injectionPart: return "Total Part Cost"
        case .sparePart, .packaging: return "Total Cost"
        default: return "Sub Total"
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
                totalRow("Sub Total", value: materialSubtotal)
            }
            Section {
                Picker("Cost of Injection / Day", selection: $costPerDay) {
                    ForEach(CostRates.injectionPerDayOptions, id: \.self) { option in
                        Text(option.rupiah).tag(option)
                    }
                }
                numberField("Cycle Time (seconds)", text: $cycleTime)
                numberField("Number of Cavities", text: $cavities)
                totalRow("Sub Total", value: injectSubtotal)
            } header: {
                Text("Inject Cost")
            } footer: {
                Text(injectFooter)
            }
        }
    }

    private var cartonFields: some View {
        Group {
            Section("Product Cost") {
                numberField("Cost of Product (Rp/Pcs)", text: $unitCost)
                totalRow("Sub Total", value: productSubtotal)
            }
            Section {
                numberField("Total pcs / Carton", text: $pcsPerCarton)
                numberField("Total m³ of Carton", text: $cubicMetres)
                numberField("Cost / m³ (Rp)", text: $ratePerCubicMetre)
                totalRow("Sub Total", value: importSubtotal)
            } header: {
                Text("Import Cost")
            } footer: {
                Text("Freight is split across the carton's pieces.")
            }
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

    /// A running total. Shows a dash until its own inputs are filled in.
    private func totalRow(_ title: String, value: Double?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value?.rupiah ?? "—")
                .foregroundStyle(value == nil ? .secondary : .primary)
        }
        .font(.headline)
    }

    /// Material half, available as soon as a weight is entered.
    private var materialSubtotal: Double? {
        guard let weight = parse(weightGrams) else { return nil }
        return InjectionBreakdown(
            weightGrams: weight,
            cycleTimeSeconds: 0,
            cavities: 0,
            material: material,
            costPerDay: costPerDay
        ).materialCost
    }

    /// Product half, available as soon as a unit cost is entered.
    private var productSubtotal: Double? {
        guard let cost = parse(unitCost) else { return nil }
        return CartonBreakdown(
            unitCost: cost,
            pcsPerCarton: 0,
            cubicMetres: 0,
            ratePerCubicMetre: 0
        ).productCost
    }

    /// Freight half, available once the carton's pieces, volume and rate are in.
    private var importSubtotal: Double? {
        guard let pcs = parse(pcsPerCarton), pcs > 0,
              let volume = parse(cubicMetres),
              let rate = parse(ratePerCubicMetre)
        else { return nil }
        return CartonBreakdown(
            unitCost: 0,
            pcsPerCarton: pcs,
            cubicMetres: volume,
            ratePerCubicMetre: rate
        ).importCost
    }

    /// Shows the working, so the sub total can be checked by eye.
    private var injectFooter: String {
        guard let breakdown = injectionInputs else {
            return "\(CostRates.secondsPerDay.compact) s ÷ cycle time × cavities = pcs / day."
        }
        return """
        \(CostRates.secondsPerDay.compact) ÷ \(breakdown.cycleTimeSeconds.compact) \
        × \(breakdown.cavities.compact) = \(breakdown.piecesPerDay.compact) pcs / day.
        """
    }

    /// The machine-side inputs, once the cycle and cavities are entered.
    private var injectionInputs: InjectionBreakdown? {
        guard let cycle = parse(cycleTime), cycle > 0,
              let cavityCount = parse(cavities), cavityCount > 0
        else { return nil }
        return InjectionBreakdown(
            weightGrams: parse(weightGrams) ?? 0,
            cycleTimeSeconds: cycle,
            cavities: cavityCount,
            material: material,
            costPerDay: costPerDay
        )
    }

    /// Machine half, available once the cycle and cavities are entered.
    private var injectSubtotal: Double? {
        injectionInputs?.injectCost
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
                  let cycle = parse(cycleTime), cycle > 0,
                  let cavityCount = parse(cavities), cavityCount > 0
            else { return nil }
            return .injection(
                weightGrams: weight,
                cycleTimeSeconds: cycle,
                cavities: cavityCount,
                material: material,
                costPerDay: costPerDay
            )

        case .sparePart, .packaging:
            guard let cost = parse(unitCost),
                  let pcs = parse(pcsPerCarton), pcs > 0,
                  let volume = parse(cubicMetres),
                  let rate = parse(ratePerCubicMetre)
            else { return nil }
            return .cartoned(
                unitCost: cost,
                pcsPerCarton: pcs,
                cubicMetres: volume,
                ratePerCubicMetre: rate
            )

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

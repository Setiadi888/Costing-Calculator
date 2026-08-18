//
//  AddCostItemView.swift
//  Costing Calculator
//

import SwiftUI

struct AddCostItemView: View {
    let category: CostCategory
    /// The item being changed, or nil when adding a new one.
    let existing: CostItem?
    let onSave: (CostItem) -> Void

    @State private var name: String

    // INJECTION PART
    @State private var weightGrams: String
    @State private var cycleTime: String
    @State private var cavities: String
    @State private var material: MouldingMaterial
    @State private var costPerDay: Double
    @State private var materialRmb: String
    @State private var materialExchangeRate: String

    // IMPORT
    @State private var importKind: ImportKind
    @State private var unitCost: String
    @State private var unitRmb: String
    @State private var unitExchangeRate: String
    @State private var pcsPerCarton: String
    @State private var cubicMetres: String
    @State private var ratePerCubicMetre: String

    // UV
    @State private var costPerTable: String
    @State private var pcsPerTable: String

    // SPRAY / PAD PRINT / LABOUR
    @State private var amount: String

    init(
        category: CostCategory,
        existing: CostItem? = nil,
        onSave: @escaping (CostItem) -> Void
    ) {
        self.category = category
        self.existing = existing
        self.onSave = onSave

        // Start from the category name so the field holds real text to edit,
        // rather than a label beside an empty box.
        _name = State(initialValue: existing?.name ?? category.rawValue.capitalized)

        // Defaults for a new item; overwritten below when editing.
        var weight = "", cycle = "", cavityCount = "1"
        var mouldingMaterial = MouldingMaterial.pp
        var perDay = CostRates.defaultInjectionPerDay
        var cost = "", pcsCarton = "", volume = ""
        var rate = CostRates.defaultFreightPerCubicMetre.plainDigits
        var tableCost = "", tablePcs = "", flatAmount = ""
        var materialYuan = "", materialRate = "", unitYuan = "", unitRate = ""
        var kind = ImportKind.sparePart

        switch existing?.details {
        case let .injection(w, c, cav, m, day, price):
            weight = w.plainDigits
            cycle = c.plainDigits
            cavityCount = cav.plainDigits
            mouldingMaterial = m
            perDay = day
            if price.rmb > 0 { materialYuan = price.rmb.plainDigits }
            if price.exchangeRate > 0 { materialRate = price.exchangeRate.plainDigits }
        case let .cartoned(price, pcs, m3, perM3, existingKind):
            cost = price.rupiah.plainDigits
            if price.rmb > 0 { unitYuan = price.rmb.plainDigits }
            if price.exchangeRate > 0 { unitRate = price.exchangeRate.plainDigits }
            pcsCarton = pcs.plainDigits
            volume = m3.plainDigits
            rate = perM3.plainDigits
            kind = existingKind
        case let .perTable(perTable, pcs):
            tableCost = perTable.plainDigits
            tablePcs = pcs.plainDigits
        case let .flat(value):
            flatAmount = value.plainDigits
        case nil:
            break
        }

        _weightGrams = State(initialValue: weight)
        _cycleTime = State(initialValue: cycle)
        _cavities = State(initialValue: cavityCount)
        _material = State(initialValue: mouldingMaterial)
        _costPerDay = State(initialValue: perDay)
        _materialRmb = State(initialValue: materialYuan)
        _materialExchangeRate = State(initialValue: materialRate)
        _importKind = State(initialValue: kind)
        _unitCost = State(initialValue: cost)
        _unitRmb = State(initialValue: unitYuan)
        _unitExchangeRate = State(initialValue: unitRate)
        _pcsPerCarton = State(initialValue: pcsCarton)
        _cubicMetres = State(initialValue: volume)
        _ratePerCubicMetre = State(initialValue: rate)
        _costPerTable = State(initialValue: tableCost)
        _pcsPerTable = State(initialValue: tablePcs)
        _amount = State(initialValue: flatAmount)
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $name)
                    .labelsHidden()
            }

            switch category {
            case .injectionPart: injectionFields
            case .importItem: cartonFields
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
                    // Keep the id when editing so this replaces the item
                    // rather than adding a second copy of it.
                    onSave(
                        CostItem(
                            id: existing?.id ?? UUID(),
                            category: category,
                            name: name,
                            details: details
                        )
                    )
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
        case .importItem: return "Total Cost"
        default: return "Sub Total"
        }
    }

    // MARK: - Category fields

    private var injectionFields: some View {
        Group {
            Section {
                numberField("Weight (gram)", text: $weightGrams)
                Picker("Type of Material", selection: $material) {
                    ForEach(MouldingMaterial.allCases) { material in
                        Text("\(material.rawValue) — \(material.ratePerKg.rupiah)/kg").tag(material)
                    }
                }
                numberField("Price in RMB / kg", text: $materialRmb)
                numberField("Exchange Rate (Rp / RMB)", text: $materialExchangeRate)
                convertedRow("Converted (Rp / kg)", price: materialPrice)
                totalRow("Sub Total", value: materialSubtotal)
            } header: {
                Text("Material")
            } footer: {
                Text(priceFooter(materialPrice, unit: "kg"))
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
            Section {
                Picker("Type", selection: $importKind) {
                    ForEach(ImportKind.allCases) { kind in
                        Text(kind.rawValue.capitalized).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            } header: {
                Text("Import Type")
            } footer: {
                Text("Kept with the item so it stays identifiable in the totals.")
            }
            Section {
                numberField("Cost of Product (Rp/Pcs)", text: $unitCost)
                numberField("Price in RMB / Pcs", text: $unitRmb)
                numberField("Exchange Rate (Rp / RMB)", text: $unitExchangeRate)
                convertedRow("Converted (Rp / Pcs)", price: unitPrice)
                totalRow("Sub Total", value: productSubtotal)
            } header: {
                Text("Product Cost")
            } footer: {
                Text(priceFooter(unitPrice, unit: "pc"))
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
            costPerDay: costPerDay,
            materialPrice: materialPrice
        ).materialCost
    }

    /// The rate per kilo: the material's own, unless an RMB price overrides it.
    private var materialPrice: PriceInput {
        PriceInput(
            rupiah: material.ratePerKg,
            rmb: parse(materialRmb) ?? 0,
            exchangeRate: parse(materialExchangeRate) ?? 0
        )
    }

    /// The cost per piece, in Rupiah or converted from RMB.
    private var unitPrice: PriceInput {
        PriceInput(
            rupiah: parse(unitCost) ?? 0,
            rmb: parse(unitRmb) ?? 0,
            exchangeRate: parse(unitExchangeRate) ?? 0
        )
    }

    /// A converted price, shown only once there is one to show.
    private func convertedRow(_ title: String, price: PriceInput) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(price.converted?.rupiah ?? "—")
                .foregroundStyle(price.isConverted ? .primary : .secondary)
        }
    }

    /// Says which of the two prices the sub total is actually using.
    private func priceFooter(_ price: PriceInput, unit: String) -> String {
        if price.isConverted {
            return "Using the RMB price: ¥\(price.rmb.compact) × \(price.exchangeRate.compact) = \(price.value.rupiah) per \(unit)."
        }
        return "Fill in both RMB and an exchange rate to price in Yuan instead."
    }

    /// Product half, available as soon as a price is entered either way.
    private var productSubtotal: Double? {
        let price = unitPrice
        guard price.isConverted || parse(unitCost) != nil else { return nil }
        return CartonBreakdown(
            unitPrice: price,
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
            unitPrice: PriceInput(),
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
            costPerDay: costPerDay,
            materialPrice: materialPrice
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
                costPerDay: costPerDay,
                materialPrice: materialPrice
            )

        case .importItem:
            // Either way of giving the price will do, so long as one is there.
            let price = unitPrice
            guard price.isConverted || parse(unitCost) != nil,
                  let pcs = parse(pcsPerCarton), pcs > 0,
                  let volume = parse(cubicMetres),
                  let rate = parse(ratePerCubicMetre)
            else { return nil }
            return .cartoned(
                unitPrice: price,
                pcsPerCarton: pcs,
                cubicMetres: volume,
                ratePerCubicMetre: rate,
                kind: importKind
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

    /// Reads a typed number. A separator that repeats is grouping, so
    /// "3.500.000" is three and a half million; a single one is a decimal
    /// point, so "1,5" and "1.5" both read as 1.5.
    private func parse(_ text: String) -> Double? {
        var cleaned = text.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }

        for separator in [".", ","] where cleaned.components(separatedBy: separator).count > 2 {
            cleaned = cleaned.replacingOccurrences(of: separator, with: "")
        }
        cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
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

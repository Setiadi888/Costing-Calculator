//
//  SellingPriceView.swift
//  Costing Calculator
//

import SwiftUI

/// Prices a finished costing. The cost it came to, divided by a figure, is
/// what it sells for — dividing by 0.8 leaves a fifth of the price as margin.
struct SellingPriceView: View {
    @Binding var product: SavedProduct

    @State private var dividerText: String
    /// The decimal pad has no return key, so iPhone needs a way out of it.
    @FocusState private var isTyping: Bool

    init(product: Binding<SavedProduct>) {
        _product = product
        _dividerText = State(
            initialValue: product.wrappedValue.sellingDivider?.plainDigits ?? ""
        )
    }

    private var divider: Double? {
        guard let value = Double(costingInput: dividerText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Total Cost", value: product.grandTotal.rupiah)
            } header: {
                Text("Cost")
            } footer: {
                Text("What the costing came to when it was saved. Change it by editing the costing itself, not here.")
            }

            Section {
                LabeledContent("Divider (÷)") {
                    TextField("Divider", text: $dividerText)
                        .multilineTextAlignment(.trailing)
                        .labelsHidden()
                        .focused($isTyping)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                figure("Selling Price", product.sellingPrice?.rupiah)
                figure("Margin", product.margin?.percent)
            } header: {
                Text("Selling Price")
            } footer: {
                Text(workingOut)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(product.name)
        .onChange(of: dividerText) { _, _ in
            product.sellingDivider = divider
        }
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isTyping = false }
            }
            #endif
        }
    }

    /// A worked-out figure. Shows a dash until there is a divider to use.
    private func figure(_ title: String, _ value: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "—")
                .foregroundStyle(value == nil ? .secondary : .primary)
        }
        .font(.headline)
    }

    /// Shows the working, so the price can be checked by eye.
    private var workingOut: String {
        guard let divider, let price = product.sellingPrice, let margin = product.margin else {
            return "The cost divided by this figure is the selling price. Divide by 0,8 to leave a fifth of the price as margin."
        }
        return "\(product.grandTotal.rupiah) ÷ \(divider.compact) = \(price.rupiah), a margin of \(margin.percent)."
    }
}

#Preview {
    // A wrapper rather than @Previewable, which needs a newer SwiftUI than
    // this app's iOS 17 floor.
    struct Harness: View {
        @State private var product = SavedProduct(
            name: "Product 1",
            items: [CostItem(category: .spray, name: "Spray", details: .flat(amount: 12_000))]
        )
        var body: some View {
            NavigationStack {
                SellingPriceView(product: $product)
            }
        }
    }
    return Harness()
}

//
//  ContentView.swift
//  Costing Calculator
//
//  Created by Setiadi Kusumo Suwignjo on 13/08/26.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: Costing_CalculatorDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(Costing_CalculatorDocument()))
}

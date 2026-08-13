//
//  ContentView.swift
//  Costing Calculator
//
//  Created by Setiadi Kusumo Suwignjo on 13/08/26.
//

import SwiftUI

private enum CalcOperation {
    case add, subtract, multiply, divide
}

private enum CalcButton: String, Hashable {
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case decimal = "."
    case equals = "="
    case add = "+", subtract = "−", multiply = "×", divide = "÷"
    case clear = "AC"
    case negate = "±"
    case percent = "%"

    var isOperator: Bool {
        switch self {
        case .add, .subtract, .multiply, .divide: return true
        default: return false
        }
    }
}

struct ContentView: View {
    @State private var display = "0"
    @State private var currentValue: Double = 0
    @State private var pendingOperation: CalcOperation?
    @State private var isEnteringNumber = false

    private let columns: [[CalcButton]] = [
        [.clear, .negate, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equals]
    ]

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(display)
                .font(.system(size: 64, weight: .light))
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)
                .foregroundStyle(.primary)

            ForEach(columns, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { button in
                        CalculatorButtonView(button: button, isWide: button == .zero) {
                            tap(button)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 280, minHeight: 480)
        .background(Color.black)
    }

    private func tap(_ button: CalcButton) {
        switch button {
        case .clear:
            display = "0"
            currentValue = 0
            pendingOperation = nil
            isEnteringNumber = false

        case .negate:
            if let value = Double(display) {
                display = formatted(value * -1)
            }

        case .percent:
            if let value = Double(display) {
                display = formatted(value / 100)
            }

        case .decimal:
            if !isEnteringNumber {
                display = "0."
                isEnteringNumber = true
            } else if !display.contains(".") {
                display += "."
            }

        case .add, .subtract, .multiply, .divide:
            applyPending()
            currentValue = Double(display) ?? 0
            pendingOperation = operation(for: button)
            isEnteringNumber = false

        case .equals:
            applyPending()
            pendingOperation = nil
            isEnteringNumber = false

        default:
            let digit = button.rawValue
            if !isEnteringNumber {
                display = digit
                isEnteringNumber = true
            } else {
                display = display == "0" ? digit : display + digit
            }
        }
    }

    private func applyPending() {
        guard let operation = pendingOperation, let rhs = Double(display) else { return }
        let result: Double
        switch operation {
        case .add: result = currentValue + rhs
        case .subtract: result = currentValue - rhs
        case .multiply: result = currentValue * rhs
        case .divide: result = rhs == 0 ? .nan : currentValue / rhs
        }
        display = formatted(result)
        currentValue = result
    }

    private func operation(for button: CalcButton) -> CalcOperation {
        switch button {
        case .add: return .add
        case .subtract: return .subtract
        case .multiply: return .multiply
        case .divide: return .divide
        default: fatalError("Not an operator")
        }
    }

    private func formatted(_ value: Double) -> String {
        if value.isNaN { return "Error" }
        if value == value.rounded() && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        return String(value)
    }
}

private struct CalculatorButtonView: View {
    let button: CalcButton
    let isWide: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(button.rawValue)
                .font(.system(size: 28, weight: .medium))
                .frame(maxWidth: isWide ? .infinity : nil)
                .frame(width: isWide ? nil : 64, height: 64)
                .frame(maxWidth: isWide ? .infinity : 64)
                .background(backgroundColor)
                .foregroundStyle(foregroundColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var backgroundColor: Color {
        switch button {
        case .clear, .negate, .percent:
            return Color(white: 0.65)
        case .add, .subtract, .multiply, .divide, .equals:
            return .orange
        default:
            return Color(white: 0.2)
        }
    }

    private var foregroundColor: Color {
        switch button {
        case .clear, .negate, .percent:
            return .black
        default:
            return .white
        }
    }
}

#Preview {
    ContentView()
}

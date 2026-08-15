//
//  CostCategory.swift
//  Costing Calculator
//

import Foundation

enum CostCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case injectionPart = "INJECTION PART"
    case sparePart = "SPAREPART"
    case packaging = "PACKAGING"
    case uv = "UV"
    case spray = "SPRAY"
    case padPrint = "PAD PRINT"
    case packagingLabourCost = "PACKAGING LABOUR COST"
    case assemblyLabourCost = "ASSEMBLY LABOUR COST"

    var id: String { rawValue }
}

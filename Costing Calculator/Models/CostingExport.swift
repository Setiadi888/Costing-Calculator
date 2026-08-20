//
//  CostingExport.swift
//  Costing Calculator
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Turns saved costings into a file worth sending on: a spreadsheet to work
/// in, or a PDF to read.
enum CostingExport {
    enum Format {
        case spreadsheet
        case pdf

        var fileExtension: String {
            switch self {
            case .spreadsheet: return "xlsx"
            case .pdf: return "pdf"
            }
        }
    }

    private static let headings = [
        "Product", "Items", "Saved", "Grand Total", "Selling Price", "Margin %"
    ]

    /// Writes the costings out and gives back the file, ready to share.
    static func file(for products: [SavedProduct], as format: Format) -> URL? {
        let data: Data?
        switch format {
        case .spreadsheet: data = spreadsheet(for: products)
        case .pdf: data = pdf(for: products)
        }
        guard let data else { return nil }

        let stamp = Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash))
        let name = "Costings \(stamp).\(format.fileExtension)"
        let url = URL.temporaryDirectory.appending(path: name)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return nil
        }
        return url
    }

    // MARK: - Rows

    /// One line per costing, matching what the saved list shows. Numbers stay
    /// numbers so a spreadsheet can add them up.
    private struct Row {
        var name: String
        var items: Int
        var saved: String
        var grandTotal: Double
        var sellingPrice: Double?
        var marginPercent: Double?
    }

    private static func rows(for products: [SavedProduct]) -> [Row] {
        products.map { product in
            Row(
                name: product.name,
                items: product.items.count,
                saved: product.savedAt.formatted(date: .abbreviated, time: .omitted),
                grandTotal: product.grandTotal,
                sellingPrice: product.sellingPrice,
                marginPercent: product.margin.map { $0 * 100 }
            )
        }
    }

    // MARK: - Spreadsheet

    /// A minimal .xlsx: a zip of the few parts a reader insists on. Text goes
    /// in as inline strings, which saves carrying a shared-strings table.
    private static func spreadsheet(for products: [SavedProduct]) -> Data? {
        var sheet = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>\
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>
        """
        sheet += row(1, headings.map { .text($0) })

        for (offset, item) in rows(for: products).enumerated() {
            sheet += row(offset + 2, [
                .text(item.name),
                .number(Double(item.items)),
                .text(item.saved),
                .number(item.grandTotal),
                item.sellingPrice.map { Cell.number($0) } ?? .text(""),
                item.marginPercent.map { Cell.number($0) } ?? .text("")
            ])
        }

        let total = products.reduce(0) { $0 + $1.grandTotal }
        let count = products.reduce(0) { $0 + $1.items.count }
        sheet += row(products.count + 2, [
            .text("Total"), .number(Double(count)), .text(""),
            .number(total), .text(""), .text("")
        ])
        sheet += "</sheetData></worksheet>"

        return zip([
            ("[Content_Types].xml", Parts.contentTypes),
            ("_rels/.rels", Parts.rels),
            ("xl/workbook.xml", Parts.workbook),
            ("xl/_rels/workbook.xml.rels", Parts.workbookRels),
            ("xl/worksheets/sheet1.xml", Data(sheet.utf8))
        ])
    }

    private enum Cell {
        case text(String)
        case number(Double)
    }

    private static func row(_ index: Int, _ cells: [Cell]) -> String {
        var xml = "<row r=\"\(index)\">"
        for (offset, cell) in cells.enumerated() {
            // Six columns, so a single letter is always enough.
            let column = String(UnicodeScalar(UInt8(65 + offset)))
            let reference = "\(column)\(index)"
            switch cell {
            case let .number(value):
                xml += "<c r=\"\(reference)\"><v>\(value)</v></c>"
            case let .text(value):
                xml += "<c r=\"\(reference)\" t=\"inlineStr\"><is><t>\(escaped(value))</t></is></c>"
            }
        }
        return xml + "</row>"
    }

    private static func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private enum Parts {
        static let contentTypes = Data("""
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>\
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\
        <Default Extension="xml" ContentType="application/xml"/>\
        <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>\
        <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>\
        </Types>
        """.utf8)

        static let rels = Data("""
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>\
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>\
        </Relationships>
        """.utf8)

        static let workbook = Data("""
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>\
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" \
        xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\
        <sheets><sheet name="Costings" sheetId="1" r:id="rId1"/></sheets></workbook>
        """.utf8)

        static let workbookRels = Data("""
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>\
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>\
        </Relationships>
        """.utf8)
    }

    // MARK: - Zip

    /// Stores the parts without compressing them. A spreadsheet is small, and
    /// stored entries need no deflate implementation to go wrong.
    private static func zip(_ entries: [(String, Data)]) -> Data {
        var archive = Data()
        var central = Data()

        for (name, data) in entries {
            let nameBytes = Data(name.utf8)
            let checksum = crc32(data)
            let offset = UInt32(archive.count)

            archive.appendLE(UInt32(0x04034b50))          // local header
            archive.appendLE(UInt16(20))                  // version needed
            archive.appendLE(UInt16(0))                   // flags
            archive.appendLE(UInt16(0))                   // stored
            archive.appendLE(UInt16(0))                   // time
            archive.appendLE(UInt16(0))                   // date
            archive.appendLE(checksum)
            archive.appendLE(UInt32(data.count))          // compressed size
            archive.appendLE(UInt32(data.count))          // uncompressed size
            archive.appendLE(UInt16(nameBytes.count))
            archive.appendLE(UInt16(0))                   // extra length
            archive.append(nameBytes)
            archive.append(data)

            central.appendLE(UInt32(0x02014b50))          // central entry
            central.appendLE(UInt16(20))                  // version made by
            central.appendLE(UInt16(20))                  // version needed
            central.appendLE(UInt16(0))                   // flags
            central.appendLE(UInt16(0))                   // stored
            central.appendLE(UInt16(0))                   // time
            central.appendLE(UInt16(0))                   // date
            central.appendLE(checksum)
            central.appendLE(UInt32(data.count))
            central.appendLE(UInt32(data.count))
            central.appendLE(UInt16(nameBytes.count))
            central.appendLE(UInt16(0))                   // extra
            central.appendLE(UInt16(0))                   // comment
            central.appendLE(UInt16(0))                   // disk
            central.appendLE(UInt16(0))                   // internal attrs
            central.appendLE(UInt32(0))                   // external attrs
            central.appendLE(offset)
            central.append(nameBytes)
        }

        let centralOffset = UInt32(archive.count)
        archive.append(central)
        archive.appendLE(UInt32(0x06054b50))              // end of directory
        archive.appendLE(UInt16(0))                       // this disk
        archive.appendLE(UInt16(0))                       // disk with directory
        archive.appendLE(UInt16(entries.count))
        archive.appendLE(UInt16(entries.count))
        archive.appendLE(UInt32(central.count))
        archive.appendLE(centralOffset)
        archive.appendLE(UInt16(0))                       // comment length
        return archive
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var table = [UInt32](repeating: 0, count: 256)
        for index in 0..<256 {
            var value = UInt32(index)
            for _ in 0..<8 {
                value = (value & 1) == 1 ? (0xEDB88320 ^ (value >> 1)) : (value >> 1)
            }
            table[index] = value
        }
        var checksum: UInt32 = 0xFFFFFFFF
        for byte in data {
            checksum = table[Int((checksum ^ UInt32(byte)) & 0xFF)] ^ (checksum >> 8)
        }
        return checksum ^ 0xFFFFFFFF
    }

    // MARK: - PDF

    private static func pdf(for products: [SavedProduct]) -> Data? {
        #if canImport(UIKit)
        // A4, in points.
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let margin: CGFloat = 40
        let widths: [CGFloat] = [170, 45, 90, 100, 100, 60]

        let renderer = UIGraphicsPDFRenderer(bounds: page)
        return renderer.pdfData { context in
            var y: CGFloat = margin
            context.beginPage()

            "Costings".draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 20)]
            )
            y += 30
            Date.now.formatted(date: .long, time: .shortened).draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: [.font: UIFont.systemFont(ofSize: 10),
                                 .foregroundColor: UIColor.secondaryLabel]
            )
            y += 26

            func line(_ cells: [String], bold: Bool) {
                let font = bold ? UIFont.boldSystemFont(ofSize: 10) : UIFont.systemFont(ofSize: 10)
                var x = margin
                for (offset, text) in cells.enumerated() {
                    let width = widths[min(offset, widths.count - 1)]
                    text.draw(
                        in: CGRect(x: x, y: y, width: width - 6, height: 16),
                        withAttributes: [.font: font]
                    )
                    x += width
                }
                y += 18
            }

            line(headings, bold: true)
            y += 2

            for item in rows(for: products) {
                // Start a fresh page before running off the bottom.
                if y > page.height - margin - 40 {
                    context.beginPage()
                    y = margin
                    line(headings, bold: true)
                    y += 2
                }
                line([
                    item.name,
                    "\(item.items)",
                    item.saved,
                    item.grandTotal.rupiah,
                    item.sellingPrice?.rupiah ?? "—",
                    item.marginPercent.map { "\($0.compact)%" } ?? "—"
                ], bold: false)
            }

            y += 6
            let total = products.reduce(0) { $0 + $1.grandTotal }
            let count = products.reduce(0) { $0 + $1.items.count }
            line(["Total", "\(count)", "", total.rupiah, "", ""], bold: true)
        }
        #else
        return nil
        #endif
    }
}

private extension Data {
    mutating func appendLE(_ value: UInt32) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 24) & 0xFF))
    }

    mutating func appendLE(_ value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
    }
}

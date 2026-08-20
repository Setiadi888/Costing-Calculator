//
//  ShareSheet.swift
//  Costing Calculator
//

import SwiftUI
import UIKit

/// A file on its way somewhere: mail, Files, WhatsApp, whatever is installed.
/// Wraps UIKit's share sheet, which SwiftUI has no equivalent of for a file
/// produced on demand.
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// A file the share sheet is being shown for. Identifiable so it can drive a
/// sheet directly.
struct ExportedFile: Identifiable {
    let url: URL
    var id: String { url.path }
}

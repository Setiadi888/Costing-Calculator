//
//  ProductImageStore.swift
//  Costing Calculator
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Keeps product photos as files of their own, next to the costings.
///
/// The costings themselves are rewritten every time anything changes, down to
/// a keystroke in a name, so a photo held inside that file would be encoded
/// and written again with it. Only the file name goes in the costing.
enum ProductImageStore {
    /// The longest side a stored photo is kept at. A costing sheet needs to
    /// show what the product is, not to reproduce it.
    private static let maxDimension: CGFloat = 1400

    private static var directory: URL? {
        guard let support = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        let images = support.appending(path: "ProductImages")
        try? FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)
        return images
    }

    static func url(for fileName: String) -> URL? {
        directory?.appending(path: fileName)
    }

    static func load(_ fileName: String?) -> Data? {
        guard let fileName, let url = url(for: fileName) else { return nil }
        return try? Data(contentsOf: url)
    }

    /// Writes a photo and gives back the name it went under, removing whatever
    /// it replaced. The name is fresh every time so nothing shows a photo that
    /// has already been swapped out.
    static func save(_ data: Data, replacing previous: String?) -> String? {
        guard let shrunk = shrink(data) else { return nil }
        let fileName = "\(UUID().uuidString).jpg"
        guard let url = url(for: fileName) else { return nil }
        do {
            try shrunk.write(to: url, options: .atomic)
        } catch {
            return nil
        }
        remove(previous)
        return fileName
    }

    static func remove(_ fileName: String?) {
        guard let fileName, let url = url(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    /// Brings a photo down to something worth keeping on a phone.
    private static func shrink(_ data: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else {
            return image.jpegData(compressionQuality: 0.8)
        }
        let scale = maxDimension / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.8)
        #else
        return data
        #endif
    }
}

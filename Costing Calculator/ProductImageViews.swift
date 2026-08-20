//
//  ProductImageViews.swift
//  Costing Calculator
//

import SwiftUI
import PhotosUI

/// The small photo at the head of a saved costing. Empty, it opens the photo
/// library; filled, it opens the photo.
struct ProductThumbnail: View {
    @Binding var product: SavedProduct

    @State private var picked: PhotosPickerItem?
    @State private var isExpanded = false
    @State private var photo: Image?

    private let side: CGFloat = 44

    var body: some View {
        Group {
            if let photo {
                Button {
                    isExpanded = true
                } label: {
                    photo
                        .resizable()
                        .scaledToFill()
                        .frame(width: side, height: side)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Photo of \(product.name). Opens it larger.")
            } else {
                PhotosPicker(selection: $picked, matching: .images) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .frame(width: side, height: side)
                        .overlay {
                            Image(systemName: "photo.badge.plus")
                                .foregroundStyle(.secondary)
                        }
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add a photo of \(product.name)")
            }
        }
        .task(id: product.imageFileName) { await reload() }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            Task { await store(item) }
        }
        .sheet(isPresented: $isExpanded) {
            ProductPhotoSheet(product: $product)
        }
    }

    private func reload() async {
        guard let data = ProductImageStore.load(product.imageFileName),
              let image = UIImage(data: data)
        else {
            photo = nil
            return
        }
        photo = Image(uiImage: image)
    }

    private func store(_ item: PhotosPickerItem) async {
        defer { picked = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        product.imageFileName = ProductImageStore.save(data, replacing: product.imageFileName)
    }
}

/// A product's photo, full size, with the way to change or drop it.
struct ProductPhotoSheet: View {
    @Binding var product: SavedProduct
    @Environment(\.dismiss) private var dismiss

    @State private var picked: PhotosPickerItem?
    @State private var photo: Image?

    var body: some View {
        NavigationStack {
            Group {
                if let photo {
                    photo
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.black)
                } else {
                    ContentUnavailableView(
                        "No Photo",
                        systemImage: "photo",
                        description: Text("Add one to see it here.")
                    )
                }
            }
            .navigationTitle(product.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    PhotosPicker("Replace", selection: $picked, matching: .images)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Remove Photo", role: .destructive) {
                        ProductImageStore.remove(product.imageFileName)
                        product.imageFileName = nil
                        dismiss()
                    }
                    .disabled(product.imageFileName == nil)
                }
            }
        }
        .task(id: product.imageFileName) { await reload() }
        .onChange(of: picked) { _, item in
            guard let item else { return }
            Task { await store(item) }
        }
    }

    private func reload() async {
        guard let data = ProductImageStore.load(product.imageFileName),
              let image = UIImage(data: data)
        else {
            photo = nil
            return
        }
        photo = Image(uiImage: image)
    }

    private func store(_ item: PhotosPickerItem) async {
        defer { picked = nil }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        product.imageFileName = ProductImageStore.save(data, replacing: product.imageFileName)
    }
}

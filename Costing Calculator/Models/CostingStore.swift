//
//  CostingStore.swift
//  Costing Calculator
//

import Foundation

/// Everything the app is holding on to at one moment: the costing being
/// worked on, and every costing already finished off.
struct CostingState: Codable, Equatable {
    var items: [CostItem] = []
    var savedProducts: [SavedProduct] = []
    /// Whether the costing being worked on adds the 7.5% lain-lain.
    var includesMiscellaneous = true
}

/// Keeps the state on disk between launches. iOS ends a backgrounded app
/// whenever it wants the memory back, so a costing held only in memory is
/// gone by the next time the app is opened.
enum CostingStore {
    /// Application Support rather than Documents: this is the app's own
    /// bookkeeping, not a file its owner manages.
    private static var fileURL: URL? {
        guard let directory = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return directory.appending(path: "CostingState.json")
    }

    static func load() -> CostingState {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else {
            return CostingState()
        }
        // Starting empty beats refusing to open: a state file this version
        // can no longer read is worth nothing either way.
        return (try? JSONDecoder().decode(CostingState.self, from: data)) ?? CostingState()
    }

    static func save(_ state: CostingState) {
        guard let fileURL, let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

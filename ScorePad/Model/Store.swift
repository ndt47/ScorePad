//
//  Store.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/4/22.
//

import Foundation

class Store: ObservableObject {
    @Published var rubbers: [Rubber] = []
    @Published var loaded = false
    let url: URL?
    
    init(url: URL = Store.defaultURL) {
        self.url = url
    }
    
    init(rubbers: [Rubber]) {
        self.url = nil
        self.rubbers = rubbers
        self.loaded = true
    }
    
    func addRubber(_ rubber: Rubber) {
        if !rubbers.contains(rubber) {
            rubbers.append(rubber)
        }
    }
    
    func deleteRubber(_ rubber: Rubber) {
        guard let found = rubbers.firstIndex(of: rubber) else { return }
        rubbers.remove(at: found)
    }
    
    func deleteRubbers(at offsets: IndexSet) {
        rubbers.remove(atOffsets: offsets)
    }
    
    func rubber(with id: Rubber.ID) -> Rubber? {
        rubbers.first { $0.id == id }
    }
    
    static var defaultURL: URL {
        try! FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
            .appendingPathComponent("rubbers.scorepad")
    }
    
    func save() async throws {
        guard let url = self.url else { return }
        let data = try JSONEncoder().encode(rubbers)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
    }
    
    func load() throws {
        guard let url = self.url else { return }
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        
        do {
            let rubbers = try JSONDecoder().decode([Rubber].self, from: data)
            self.rubbers = rubbers
        } catch {
            print("Deleting data file: \(url) due to \(String(describing: error))")
            try FileManager.default.removeItem(at: url)
        }
        self.loaded = true
    }
    
    func loadIfNecessary() throws {
        if !loaded {
            try load()
        }
    }
}


extension Store {
    static var mock: Store { Store(rubbers: [.mock, .mock, .mock, .mock]) }
}

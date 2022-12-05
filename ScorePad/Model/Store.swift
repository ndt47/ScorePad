//
//  Store.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/4/22.
//

import Foundation

class Store: ObservableObject {
    @Published var rubbers: [Rubber]
    
    init(rubbers: [Rubber] = []) {
        self.rubbers = rubbers
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
    
    static func defaultURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                       in: .userDomainMask,
                                       appropriateFor: nil,
                                       create: false)
            .appendingPathComponent("rubbers.scorepad")
    }
    
    func save() async throws {
        let url = try Self.defaultURL()
        let data = try JSONEncoder().encode(rubbers)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
    }
    
    func load() throws {
        let url = try Self.defaultURL()
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let rubbers = try JSONDecoder().decode([Rubber].self, from: data)
        
        self.rubbers = rubbers
    }
}


extension Store {
    static var mock: Store { Store(rubbers: [.mock, .mock, .mock, .mock]) }
}

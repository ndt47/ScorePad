//
//  NewRubber.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/4/22.
//

import SwiftUI

struct NewRubber: View {
    var store: Store
    @State var dealer: Position = .north
    @State var north: String = ""
    @State var east: String = ""
    @State var south: String = ""
    @State var west: String = ""
    @Environment(\.dismiss) var dismiss

    enum Action {
        case save
        case cancel
        
        var label: String {
            switch self {
            case .save: return "Save"
            case .cancel: return "Cancel"
            }
        }
        
        var systemImage: String {
            switch self {
            case .save: return "pencil"
            case .cancel: return "pencil.slash"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Team.we.label)
                            .font(.title2)
                            .bold()
                        TextField(Position.north.label, text: $north)
                        TextField(Position.south.label, text: $south)
                    }
                    Divider()
                        .frame(height:120)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Team.they.label)
                            .font(.title2)
                            .bold()
                        TextField(Position.east.label, text: $west)
                        TextField(Position.west.label, text: $east)
                    }
                }
                HStack {
                    Text("Dealer:")
                        .font(.title2)
                    Picker("Dealer", selection: $dealer) {
                        ForEach(Position.allCases, id: \.self) {
                            Text($0.label)
                        }
                    }
                        .pickerStyle(.segmented)
                }
                Button {
                    if let random = Position(rawValue: Int.random(in: 0...3)) {
                        dealer = random
                    }
                } label: {
                    Label {
                        Text("Random Dealer")
                    } icon: {
                        Image(systemName: "dice.fill")
                    }

                }
                Spacer()
            }
            .textFieldStyle(.roundedBorder)
            .padding()
            .navigationTitle("New Rubber")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        save()
                    }, label: {
                        Label(Action.save.label, systemImage: Action.save.systemImage)
                    })
                    .labelStyle(.titleOnly)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        cancel()
                    }, label: {
                        Label(Action.cancel.label, systemImage: Action.cancel.systemImage)
                    })
                    .labelStyle(.titleOnly)
                }
            }
        }
    }
    
    func name(for position: Position) -> String? {
        var string: String = ""
        switch position {
        case .north:
            string = north
        case .east:
            string = east
        case .south:
            string = south
        case .west:
            string = west
        }
        string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return string.isEmpty ? nil : string
    }
    
    var players: [Player] {
        Position.allCases.compactMap { pos in
            guard let name = name(for: pos) else { return nil }
            return Player(name: name, position: pos)
        }
    }
    
    func save() {
        let rubber = Rubber(players: players, dealer: dealer)
        store.addRubber(rubber)
        Task {
            do {
                try await store.save()
            }
            catch {
                print(String(describing: error))
            }
        }
        dismiss()
    }
    
    func cancel() {
        dismiss()
    }
}

struct NewRubber_Previews: PreviewProvider {
    static var previews: some View {
        NewRubber(store: .mock)
    }
}

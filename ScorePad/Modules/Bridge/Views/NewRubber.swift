//
//  NewRubber.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/4/22.
//

import SwiftUI
import SwiftData

struct NewRubber: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PersonProfile.name) private var roster: [PersonProfile]

    @State var dealer: Position = .north
    @State var north: String = ""
    @State var east: String = ""
    @State var south: String = ""
    @State var west: String = ""
    @Environment(\.dismiss) var dismiss
    var onSave: ((Rubber.ID) -> Void)? = nil
    var onCancel: (() -> Void)? = nil

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
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Team.we.label)
                            .font(.title2)
                            .bold()
                        PlayerPickerField(Position.north.label, text: $north)
                        PlayerPickerField(Position.south.label, text: $south)
                    }
                    Divider()
                        .frame(height:120)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Team.they.label)
                            .font(.title2)
                            .bold()
                        PlayerPickerField(Position.east.label, text: $east)
                        PlayerPickerField(Position.west.label, text: $west)
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
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        save()
                    }, label: {
                        Label(Action.save.label, systemImage: Action.save.systemImage)
                    })
                    .labelStyle(.titleOnly)
                }
                #else
                ToolbarItem {
                    Button(action: {
                        save()
                    }, label: {
                        Label(Action.save.label, systemImage: Action.save.systemImage)
                    })
                    .labelStyle(.titleOnly)
                }

                #endif
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        cancel()
                    }, label: {
                        Label(Action.cancel.label, systemImage: Action.cancel.systemImage)
                    })
                    .labelStyle(.titleOnly)
                }

                #else
                ToolbarItem {
                    Button(action: {
                        cancel()
                    }, label: {
                        Label(Action.cancel.label, systemImage: Action.cancel.systemImage)
                    })
                    .labelStyle(.titleOnly)
                }
                #endif
            }
        }
        .presentationDetents([.medium])
        .edgesIgnoringSafeArea(.all)
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
        // Auto-add any new names to the shared roster
        for player in players {
            let name = player.name
            if !roster.contains(where: { $0.name.lowercased() == name.lowercased() }) {
                modelContext.insert(PersonProfile(name: name))
            }
        }
        let rubber = Rubber(players: players, dealer: dealer)
        modelContext.insert(rubber)
        onSave?(rubber.id)
        dismiss()
    }
    
    func cancel() {
        onCancel?()
        dismiss()
    }
}

struct NewRubber_Previews: PreviewProvider {
    static var previews: some View {
        NewRubber()
    }
}

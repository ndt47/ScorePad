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
    @State var north = "";  @State private var northSelection: PersonProfile? = nil
    @State var east  = "";  @State private var eastSelection:  PersonProfile? = nil
    @State var south = "";  @State private var southSelection: PersonProfile? = nil
    @State var west  = "";  @State private var westSelection:  PersonProfile? = nil
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
                        PlayerPickerField(Position.north.label, text: $north, selection: $northSelection)
                        PlayerPickerField(Position.south.label, text: $south, selection: $southSelection)
                    }
                    Divider()
                        .frame(height:120)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Team.they.label)
                            .font(.title2)
                            .bold()
                        PlayerPickerField(Position.east.label, text: $east, selection: $eastSelection)
                        PlayerPickerField(Position.west.label, text: $west, selection: $westSelection)
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

    func save() {
        // If the user selected from the suggestion list, use the captured profile directly.
        // If they typed a name without selecting, fall back to roster lookup / creation.
        func makePlayer(_ name: String, _ selection: PersonProfile?, _ position: Position) -> Player? {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            if let profile = selection { return Player(ref: PlayerRef(profile: profile), position: position) }
            let profile = roster.first(where: { $0.name.lowercased() == trimmed.lowercased() })
                ?? { let p = PersonProfile(name: trimmed); modelContext.insert(p); return p }()
            return Player(ref: PlayerRef(profile: profile), position: position)
        }

        let linked = [
            makePlayer(north, northSelection, .north),
            makePlayer(east,  eastSelection,  .east),
            makePlayer(south, southSelection, .south),
            makePlayer(west,  westSelection,  .west)
        ].compactMap { $0 }

        let rubber = Rubber(players: linked, dealer: dealer)
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

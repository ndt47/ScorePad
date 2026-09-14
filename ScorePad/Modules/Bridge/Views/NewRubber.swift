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
    @State private var north = PlayerSlot()
    @State private var east  = PlayerSlot()
    @State private var south = PlayerSlot()
    @State private var west  = PlayerSlot()
    @State private var saveError: String?
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
                        PlayerPickerField(Position.north.label, slot: $north)
                        PlayerPickerField(Position.south.label, slot: $south)
                    }
                    Divider()
                        .frame(height:120)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Team.they.label)
                            .font(.title2)
                            .bold()
                        PlayerPickerField(Position.east.label, slot: $east)
                        PlayerPickerField(Position.west.label, slot: $west)
                    }
                }
                if let problem {
                    Text(problem)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                    .disabled(problem != nil)
                }
                #else
                ToolbarItem {
                    Button(action: {
                        save()
                    }, label: {
                        Label(Action.save.label, systemImage: Action.save.systemImage)
                    })
                    .labelStyle(.titleOnly)
                    .disabled(problem != nil)
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
            .errorAlert($saveError)
        }
        .presentationDetents([.medium])
        .edgesIgnoringSafeArea(.all)
    }

    private var seats: [(slot: PlayerSlot, position: Position)] {
        [(north, .north), (east, .east), (south, .south), (west, .west)]
    }

    private var problem: String? {
        PlayerSlot.problem(with: seats.map(\.slot), roster: roster)
    }

    func save() {
        guard problem == nil else { return }
        do {
            let profiles = try PlayerSlot.resolve(seats.map(\.slot), in: modelContext)
            let players = zip(profiles, seats).map { Player(ref: PlayerRef(profile: $0), position: $1.position) }
            let rubber = Rubber(players: players, dealer: dealer)
            modelContext.insert(rubber)
            onSave?(rubber.id)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    func cancel() {
        onCancel?()
        dismiss()
    }
}

struct NewRubber_Previews: PreviewProvider {
    static var previews: some View {
        NewRubber()
            .modelContainer(for: [Rubber.self, PersonProfile.self], inMemory: true)
    }
}

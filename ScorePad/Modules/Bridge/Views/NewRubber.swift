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

    @State var dealer: Position = .north
    @State private var northProfile: PersonProfile? = nil
    @State private var eastProfile:  PersonProfile? = nil
    @State private var southProfile: PersonProfile? = nil
    @State private var westProfile:  PersonProfile? = nil
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
                        PlayerPickerField(Position.north.label, profile: $northProfile)
                        PlayerPickerField(Position.south.label, profile: $southProfile)
                    }
                    Divider()
                        .frame(height:120)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Team.they.label)
                            .font(.title2)
                            .bold()
                        PlayerPickerField(Position.east.label, profile: $eastProfile)
                        PlayerPickerField(Position.west.label, profile: $westProfile)
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
        func makePlayer(_ profile: PersonProfile?, _ position: Position) -> Player? {
            profile.map { Player(ref: PlayerRef(profile: $0), position: position) }
        }

        let linked = [
            makePlayer(northProfile, .north),
            makePlayer(eastProfile,  .east),
            makePlayer(southProfile, .south),
            makePlayer(westProfile,  .west)
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

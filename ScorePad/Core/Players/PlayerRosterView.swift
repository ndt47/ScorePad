import SwiftUI
import SwiftData

struct PlayerRosterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonProfile.name) private var players: [PersonProfile]

    @State private var newName = ""
    @State private var editingPlayer: PersonProfile?
    @State private var editName = ""
    @FocusState private var newNameFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add player…", text: $newName)
                            .focused($newNameFocused)
                            .onSubmit { addPlayer() }
                        if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button(action: addPlayer) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if !players.isEmpty {
                    Section("Players") {
                        ForEach(players) { player in
                            if editingPlayer?.id == player.id {
                                HStack {
                                    TextField("Name", text: $editName)
                                        .onSubmit { commitEdit() }
                                    Button("Done", action: commitEdit)
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.tint)
                                }
                            } else {
                                Text(player.name)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            modelContext.delete(player)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            editingPlayer = player
                                            editName = player.name
                                        } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }
                                        .tint(.orange)
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addPlayer() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !players.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else {
            newName = ""
            return
        }
        modelContext.insert(PersonProfile(name: trimmed))
        newName = ""
    }

    private func commitEdit() {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            editingPlayer?.name = trimmed
        }
        editingPlayer = nil
    }
}

import SwiftUI
import SwiftData

private struct BulkMergeRoute: Hashable {}

struct PlayerRosterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonProfile.name) private var players: [PersonProfile]

    @State private var newName = ""
    @FocusState private var newNameFocused: Bool
    @State private var navigationPath = NavigationPath()

    @State private var searchText = ""
    @State private var isEditing = false
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var showBulkDeleteConfirm = false
    @State private var bulkMergeCandidates: [PersonProfile] = []

    private var filteredPlayers: [PersonProfile] {
        guard !searchText.isEmpty else { return players }
        return players.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.aliases.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if !isEditing && searchText.isEmpty {
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
                }
                if !filteredPlayers.isEmpty {
                    Section {
                        ForEach(filteredPlayers) { player in
                            playerRow(player)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search players")
            .safeAreaInset(edge: .bottom) {
                if isEditing && !selectedIDs.isEmpty { bulkActionBar }
            }
            .navigationTitle("Players")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                if isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isEditing = false
                            selectedIDs = []
                        }
                    }
                } else if !players.isEmpty {
                    ToolbarItem(placement: .automatic) {
                        Button("Select") { isEditing = true }
                    }
                }
            }
            .navigationDestination(for: PersonProfile.self) { profile in
                PersonProfileDetailView(profile: profile)
            }
            .navigationDestination(for: BulkMergeRoute.self) { _ in
                BulkMergePrimaryPickerView(candidates: bulkMergeCandidates) {
                    isEditing = false
                    selectedIDs = []
                }
            }
            .alert(bulkDeleteTitle, isPresented: $showBulkDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    let toDelete = players.filter { selectedIDs.contains($0.persistentModelID) }
                    for profile in toDelete { modelContext.delete(profile) }
                    isEditing = false
                    selectedIDs = []
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(bulkDeleteMessage)
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 500)
        #endif
    }

    @ViewBuilder
    private func playerRow(_ player: PersonProfile) -> some View {
        if isEditing {
            let isSelected = selectedIDs.contains(player.persistentModelID)
            Button {
                if isSelected { selectedIDs.remove(player.persistentModelID) }
                else { selectedIDs.insert(player.persistentModelID) }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        .imageScale(.large)
                    PlayerProfileCell(profile: player)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            Button { navigationPath.append(player) } label: {
                HStack {
                    PlayerProfileCell(profile: player)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) { modelContext.delete(player) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .contextMenu {
                Button(role: .destructive) { modelContext.delete(player) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var bulkActionBar: some View {
        HStack {
            Button(role: .destructive) { showBulkDeleteConfirm = true } label: {
                Label("Delete", systemImage: "trash")
            }
            Spacer()
            Button {
                bulkMergeCandidates = players.filter { selectedIDs.contains($0.persistentModelID) }
                navigationPath.append(BulkMergeRoute())
            } label: {
                Text("Merge")
            }
            .disabled(selectedIDs.count < 2)
        }
        .padding()
        .background(.regularMaterial)
    }

    private var bulkDeleteTitle: String {
        let n = selectedIDs.count
        return "Delete \(n) Player\(n == 1 ? "" : "s")?"
    }

    private var bulkDeleteMessage: String {
        let names = players.filter { selectedIDs.contains($0.persistentModelID) }.map { $0.name }
        guard !names.isEmpty else { return "" }
        if names.count <= 3 { return names.joined(separator: ", ") + " will be permanently deleted." }
        return "\(names.prefix(2).joined(separator: ", ")), and \(names.count - 2) more will be permanently deleted."
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
}

#Preview {
    let container = try! ModelContainer(
        for: PersonProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let profiles: [(name: String, aliases: [String])] = [
        ("Alice", []),
        ("Bobby", ["Bob", "Robert"]),
        ("Charlie", ["Chuck"]),
        ("Diana", []),
        ("Ed", ["Edward", "Eddie"]),
    ]
    for (name, aliases) in profiles {
        let p = PersonProfile(name: name)
        p.aliases = aliases
        container.mainContext.insert(p)
    }

    return PlayerRosterView()
        .modelContainer(container)
}

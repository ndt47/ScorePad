import SwiftUI
import SwiftData

struct PersonProfileDetailView: View {
    let profile: PersonProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonProfile.name) private var allProfiles: [PersonProfile]

    @State private var draftName: String
    @FocusState private var nameFieldFocused: Bool
    @State private var newAlias = ""
    @FocusState private var newAliasFocused: Bool
    @State private var showAliasPicker = false
    @State private var showDeleteConfirm = false

    init(profile: PersonProfile) {
        self.profile = profile
        self._draftName = State(initialValue: profile.name)
    }

    private var hasOtherProfiles: Bool {
        allProfiles.contains { $0.persistentModelID != profile.persistentModelID }
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $draftName)
                    .focused($nameFieldFocused)
                    .onSubmit { commitRename() }
                    .onChange(of: nameFieldFocused) { _, focused in
                        if !focused { commitRename() }
                    }
                    .onChange(of: profile.name) { _, newName in
                        if !nameFieldFocused { draftName = newName }
                    }
            }

            Section("Aliases") {
                ForEach(profile.aliases, id: \.self) { alias in
                    Text(alias)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                try? deleteAlias(alias, from: profile, context: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                HStack {
                    TextField("Add alias…", text: $newAlias)
                        .focused($newAliasFocused)
                        .onSubmit { addAlias() }
                    if !newAlias.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button(action: addAlias) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.tint)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if hasOtherProfiles {
                    Button("Select Aliases…") {
                        showAliasPicker = true
                    }
                }
            }

            Section {
                Button("Delete Player", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
        #if os(macOS)
        .formStyle(.grouped)
        #endif
        .navigationTitle(profile.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showAliasPicker) {
            AliasPickerView(primaryProfile: profile)
        }
        .alert("Delete \(profile.name)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                modelContext.delete(profile)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This player and all their aliases will be permanently deleted.")
        }
    }

    private func commitRename() {
        renameProfile(profile, to: draftName)
        draftName = profile.name
    }

    private func addAlias() {
        let trimmed = newAlias.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              trimmed.lowercased() != profile.name.lowercased(),
              !profile.aliases.contains(where: { $0.lowercased() == trimmed.lowercased() }) else {
            newAlias = ""
            return
        }
        profile.aliases.append(trimmed)
        newAlias = ""
    }
}

#Preview("With aliases") {
    let container = try! ModelContainer(
        for: PersonProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let profile = PersonProfile(name: "Bobby")
    profile.aliases = ["Bob", "Robert"]
    container.mainContext.insert(profile)
    container.mainContext.insert(PersonProfile(name: "Alice"))
    container.mainContext.insert(PersonProfile(name: "Charlie"))

    return NavigationStack {
        PersonProfileDetailView(profile: profile)
    }
    .modelContainer(container)
}

#Preview("No aliases") {
    let container = try! ModelContainer(
        for: PersonProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let profile = PersonProfile(name: "Diana")
    container.mainContext.insert(profile)

    return NavigationStack {
        PersonProfileDetailView(profile: profile)
    }
    .modelContainer(container)
}

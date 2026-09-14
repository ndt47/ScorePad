import SwiftUI
import SwiftData

struct PersonProfileDetailView: View {
    let profile: PersonProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(GameRegistry.self) private var registry
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonProfile.name) private var allProfiles: [PersonProfile]

    @State private var draftName: String
    @FocusState private var nameFieldFocused: Bool
    @State private var newAlias = ""
    @FocusState private var newAliasFocused: Bool
    @State private var showAliasPicker = false
    @State private var showDeleteConfirm = false
    @State private var gameCount = 0
    @State private var errorMessage: String?
    // Set once the profile is deleted; its properties must not be read after that.
    @State private var isDeleted = false

    init(profile: PersonProfile) {
        self.profile = profile
        self._draftName = State(initialValue: profile.name)
    }

    private var service: PlayerProfileService {
        PlayerProfileService(context: modelContext, modules: registry.modules)
    }

    private var hasOtherProfiles: Bool {
        allProfiles.contains { $0.persistentModelID != profile.persistentModelID }
    }

    var body: some View {
        if isDeleted {
            Color.clear
        } else {
            form
        }
    }

    private var form: some View {
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
                                perform { try service.removeAlias(alias, from: profile) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                HStack {
                    TextField("Add alias…", text: $newAlias)
                        .focused($newAliasFocused)
                        .onSubmit { addAlias() }
                    if !newAlias.normalizedName.isEmpty {
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
                .disabled(gameCount > 0)
            } footer: {
                if gameCount > 0 {
                    Text("\(profile.name) appears in \(gameCount) game\(gameCount == 1 ? "" : "s"), so they can't be deleted. To remove this player, add them as an alias of another player.")
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
        .task { refreshGameCount() }
        .onDisappear { commitRename() }
        .sheet(isPresented: $showAliasPicker, onDismiss: refreshGameCount) {
            AliasPickerView(primaryProfile: profile)
        }
        .alert("Delete \(profile.name)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                perform {
                    try service.delete([profile])
                    isDeleted = true
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This player and all their aliases will be permanently deleted.")
        }
        .errorAlert($errorMessage)
    }

    private func refreshGameCount() {
        perform { gameCount = try service.gameCounts()[profile.id, default: 0] }
    }

    private func commitRename() {
        guard !isDeleted else { return }
        perform { try service.rename(profile, to: draftName) }
        draftName = profile.name
    }

    private func addAlias() {
        perform { try service.addAlias(newAlias, to: profile) }
        newAlias = ""
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("With aliases") {
    let container = try! ModelContainer(
        for: ScorePadApp.schema,
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
    .environment(GameRegistry(modules: ScorePadApp.modules))
}

#Preview("No aliases") {
    let container = try! ModelContainer(
        for: ScorePadApp.schema,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let profile = PersonProfile(name: "Diana")
    container.mainContext.insert(profile)

    return NavigationStack {
        PersonProfileDetailView(profile: profile)
    }
    .modelContainer(container)
    .environment(GameRegistry(modules: ScorePadApp.modules))
}

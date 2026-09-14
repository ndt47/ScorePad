import SwiftUI
import SwiftData

struct AliasPickerView: View {
    let primaryProfile: PersonProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(GameRegistry.self) private var registry
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonProfile.name) private var allProfiles: [PersonProfile]
    @State private var searchText = ""
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var showConfirmation = false
    @State private var errorMessage: String?

    private var candidates: [PersonProfile] {
        allProfiles.filter { $0.persistentModelID != primaryProfile.persistentModelID }
    }

    private var filteredCandidates: [PersonProfile] {
        guard !searchText.isEmpty else { return candidates }
        return candidates.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
                || $0.aliases.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var selectedProfiles: [PersonProfile] {
        candidates.filter { selectedIDs.contains($0.persistentModelID) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCandidates) { profile in
                    let isSelected = selectedIDs.contains(profile.persistentModelID)
                    Button {
                        if isSelected { selectedIDs.remove(profile.persistentModelID) }
                        else { selectedIDs.insert(profile.persistentModelID) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                                .imageScale(.large)
                            PlayerProfileCell(profile: profile)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $searchText, prompt: "Search players")
            .navigationTitle("Select Aliases")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedIDs.count))") { showConfirmation = true }
                        .disabled(selectedIDs.isEmpty)
                }
            }
            .alert(confirmationTitle, isPresented: $showConfirmation) {
                Button("Merge", role: .destructive) {
                    do {
                        try PlayerProfileService(context: modelContext, modules: registry.modules)
                            .merge(selectedProfiles, into: primaryProfile)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(confirmationMessage)
            }
            .errorAlert($errorMessage)
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 440)
        #endif
    }

    private var confirmationTitle: String {
        let n = selectedIDs.count
        return "Add \(n) Alias\(n == 1 ? "" : "es")?"
    }

    private var confirmationMessage: String {
        let names = selectedProfiles.map { $0.fullName }.joined(separator: ", ")
        let n = selectedIDs.count
        return "\(names) will become \(n == 1 ? "an alias" : "aliases") of \"\(primaryProfile.fullName)\". All game records will be linked to \"\(primaryProfile.fullName)\"."
    }
}

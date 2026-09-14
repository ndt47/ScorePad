import SwiftUI
import SwiftData

struct BulkMergePrimaryPickerView: View {
    let candidates: [PersonProfile]
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(GameRegistry.self) private var registry
    @Environment(\.dismiss) private var dismiss
    @State private var primaryID: PersistentIdentifier?
    @State private var showConfirmation = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("Choose which profile to keep. The others will become aliases of it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }
            Section {
                ForEach(candidates) { profile in
                    let isPrimary = primaryID == profile.persistentModelID
                    Button {
                        primaryID = profile.persistentModelID
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isPrimary ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(isPrimary ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                                .imageScale(.large)
                            PlayerProfileCell(profile: profile)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Keep Profile")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Merge") { showConfirmation = true }
                    .disabled(primaryID == nil)
            }
        }
        .alert("Merge Profiles?", isPresented: $showConfirmation) {
            Button("Merge", role: .destructive) {
                performMerge()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let primary = candidates.first(where: { $0.persistentModelID == primaryID }) {
                let others = candidates.filter { $0.persistentModelID != primaryID }
                let names = others.map { $0.name }.joined(separator: ", ")
                Text("\(names) will become \(others.count == 1 ? "an alias" : "aliases") of \"\(primary.name)\".")
            }
        }
        .errorAlert($errorMessage)
    }

    private func performMerge() {
        guard let primaryID,
              let primary = candidates.first(where: { $0.persistentModelID == primaryID }) else { return }
        let secondaries = candidates.filter { $0.persistentModelID != primaryID }
        do {
            try PlayerProfileService(context: modelContext, modules: registry.modules)
                .merge(secondaries, into: primary)
            onComplete()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

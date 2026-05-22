import SwiftUI
import SwiftData

/// The Core session list view. A single generic parameter is the only configuration
/// needed — the Session type provides everything else via GameSession protocol requirements.
struct GameSessionList<Session: GameSession>: View {
    @Query private var sessions: [Session]
    @Binding var selectedSessionID: String?
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewSession = false
    @State private var editMode: EditMode = .inactive
    @State private var editSelection: Set<String> = []

    init(selectedSessionID: Binding<String?>) {
        _sessions = Query(Session.fetchDescriptor)
        _selectedSessionID = selectedSessionID
    }

    private var open: [Session] { sessions.filter { !$0.isFinished } }
    private var closed: [Session] { sessions.filter(\.isFinished) }

    var body: some View {
        List(selection: $editSelection) {
            if !open.isEmpty {
                Section(Session.openSectionTitle) {
                    ForEach(open, id: \.sessionID) { session in
                        Session.CellView(session: session).tag(session.sessionID)
                    }
                    .onDelete { offsets in
                        delete(offsets.map { open[$0] })
                    }
                }
            }
            if !closed.isEmpty {
                Section(Session.closedSectionTitle) {
                    ForEach(closed, id: \.sessionID) { session in
                        Session.CellView(session: session).tag(session.sessionID)
                    }
                    .onDelete { offsets in
                        delete(offsets.map { closed[$0] })
                    }
                }
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, $editMode)
        .navigationTitle(Session.navigationTitle)
        .onAppear {
            if open.isEmpty && closed.isEmpty {
                showingNewSession = true
            } else {
                editSelection = selectedSessionID.map { [$0] } ?? []
            }
        }
        // Sync List selection → navigation when browsing (not editing)
        .onChange(of: editSelection) { _, newValue in
            guard !editMode.isEditing else { return }
            selectedSessionID = newValue.first
        }
        // Sync external navigation changes (e.g. new session saved) → List highlight
        .onChange(of: selectedSessionID) { _, newValue in
            guard !editMode.isEditing else { return }
            editSelection = newValue.map { [$0] } ?? []
        }
        // Restore single-item selection when leaving edit mode
        .onChange(of: editMode) { _, newValue in
            if !newValue.isEditing {
                editSelection = selectedSessionID.map { [$0] } ?? []
            }
        }
        .toolbar {
            if editMode.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Delete", role: .destructive) {
                        deleteSelected()
                    }
                    .disabled(editSelection.isEmpty)
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                if editMode.isEditing {
                    Button("Done") {
                        withAnimation { editMode = .inactive }
                    }
                } else {
                    Button("Edit") {
                        withAnimation { editMode = .active }
                    }
                    Button {
                        showingNewSession = true
                    } label: {
                        Label(Session.newButtonTitle, systemImage: "plus")
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
        .sheet(isPresented: $showingNewSession) {
            Session.NewSessionView(onSave: { id in
                editMode = .inactive
                selectedSessionID = id
            })
        }
    }

    private func delete(_ toDelete: [Session]) {
        if toDelete.contains(where: { $0.sessionID == selectedSessionID }) {
            selectedSessionID = nil
        }
        withAnimation {
            toDelete.forEach { modelContext.delete($0) }
        }
    }

    private func deleteSelected() {
        delete(sessions.filter { editSelection.contains($0.sessionID) })
        editSelection = []
        editMode = .inactive
    }
}

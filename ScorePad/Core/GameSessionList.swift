import SwiftUI
import SwiftData

/// The Core session list view. A single generic parameter is the only configuration
/// needed — the Session type provides everything else via GameSession protocol requirements.
struct GameSessionList<Session: GameSession>: View {
    @Query private var sessions: [Session]
    @Binding var selectedSessionID: String?
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewSession = false

    init(selectedSessionID: Binding<String?>) {
        _sessions = Query(Session.fetchDescriptor)
        _selectedSessionID = selectedSessionID
    }

    private var open: [Session] { sessions.filter { !$0.isFinished } }
    private var closed: [Session] { sessions.filter(\.isFinished) }

    var body: some View {
        List(selection: $selectedSessionID) {
            if !open.isEmpty {
                Section(Session.openSectionTitle) {
                    ForEach(open, id: \.sessionID) { session in
                        Session.CellView(session: session).tag(session.sessionID as String?)
                    }
                    .onDelete { offsets in
                        withAnimation { offsets.forEach { modelContext.delete(open[$0]) } }
                    }
                }
            }
            if !closed.isEmpty {
                Section(Session.closedSectionTitle) {
                    ForEach(closed, id: \.sessionID) { session in
                        Session.CellView(session: session).tag(session.sessionID as String?)
                    }
                    .onDelete { offsets in
                        withAnimation { offsets.forEach { modelContext.delete(closed[$0]) } }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(Session.navigationTitle)
        .onAppear {
            // Auto-open the new-game sheet when there are no sessions yet, so the
            // user lands directly in creation rather than staring at an empty list.
            if open.isEmpty && closed.isEmpty { showingNewSession = true }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showingNewSession = true
                } label: {
                    Label(Session.newButtonTitle, systemImage: "plus")
                }
                .labelStyle(.titleOnly)
            }
        }
        .sheet(isPresented: $showingNewSession) {
            Session.NewSessionView(onSave: { selectedSessionID = $0 })
        }
    }
}

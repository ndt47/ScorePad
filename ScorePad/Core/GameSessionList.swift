import SwiftUI
import SwiftData

/// The Core session list — owns fetching, sectioning, selection, delete, and new-session sheet.
///
/// Modules configure it via GameModule.sessionListView(selectedSessionID:) by supplying
/// a FetchDescriptor, section/nav titles, a cell view builder, and a new-session view builder.
/// No per-module session list view is needed.
struct GameSessionList<Session: PersistentModel & GameSession, Cell: View, NewSession: View>: View {
    @Query private var sessions: [Session]
    var openSectionTitle: String
    var closedSectionTitle: String
    var navigationTitle: String
    var newButtonTitle: String
    var showsNewOnEmpty: Bool
    @Binding var selectedSessionID: String?
    @Environment(\.modelContext) private var modelContext
    @State private var showingNewSession = false
    @ViewBuilder let cell: (Session) -> Cell
    let makeNewSessionView: (Binding<String?>) -> NewSession

    init(
        fetchDescriptor: FetchDescriptor<Session>,
        openSectionTitle: String = "Open",
        closedSectionTitle: String = "Finished",
        navigationTitle: String = "Sessions",
        newButtonTitle: String = "New",
        showsNewOnEmpty: Bool = true,
        selectedSessionID: Binding<String?>,
        @ViewBuilder cell: @escaping (Session) -> Cell,
        @ViewBuilder makeNewSessionView: @escaping (Binding<String?>) -> NewSession
    ) {
        _sessions = Query(fetchDescriptor)
        self.openSectionTitle = openSectionTitle
        self.closedSectionTitle = closedSectionTitle
        self.navigationTitle = navigationTitle
        self.newButtonTitle = newButtonTitle
        self.showsNewOnEmpty = showsNewOnEmpty
        self._selectedSessionID = selectedSessionID
        self.cell = cell
        self.makeNewSessionView = makeNewSessionView
    }

    private var open: [Session] { sessions.filter { !$0.isFinished } }
    private var closed: [Session] { sessions.filter(\.isFinished) }

    var body: some View {
        List(selection: $selectedSessionID) {
            if !open.isEmpty {
                Section(openSectionTitle) {
                    ForEach(open, id: \.sessionID) { session in
                        cell(session).tag(session.sessionID as String?)
                    }
                    .onDelete { offsets in
                        withAnimation { offsets.forEach { modelContext.delete(open[$0]) } }
                    }
                }
            }
            if !closed.isEmpty {
                Section(closedSectionTitle) {
                    ForEach(closed, id: \.sessionID) { session in
                        cell(session).tag(session.sessionID as String?)
                    }
                    .onDelete { offsets in
                        withAnimation { offsets.forEach { modelContext.delete(closed[$0]) } }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(navigationTitle)
        .onAppear {
            if showsNewOnEmpty && open.isEmpty && closed.isEmpty { showingNewSession = true }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showingNewSession = true
                } label: {
                    Label(newButtonTitle, systemImage: "plus")
                }
                .labelStyle(.titleOnly)
            }
        }
        .sheet(isPresented: $showingNewSession) {
            makeNewSessionView($selectedSessionID)
        }
    }
}

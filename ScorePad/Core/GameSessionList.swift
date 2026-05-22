import SwiftUI

/// A generic session list used by all game modules.
///
/// Core owns the list structure, section logic, selection binding, delete animation,
/// new-session toolbar button, and empty-state auto-trigger. The module supplies
/// the fetched data, section titles, and cell view.
struct GameSessionList<Session: GameSession, Cell: View>: View {
    let open: [Session]
    let closed: [Session]
    var openSectionTitle: String
    var closedSectionTitle: String
    var navigationTitle: String
    var newButtonTitle: String
    var showsNewSessionOnEmpty: Bool
    @Binding var selectedSessionID: String?
    let onNew: () -> Void
    let onDelete: (IndexSet, [Session]) -> Void
    @ViewBuilder let cell: (Session) -> Cell

    init(
        open: [Session],
        closed: [Session],
        openSectionTitle: String = "Open",
        closedSectionTitle: String = "Finished",
        navigationTitle: String = "Sessions",
        newButtonTitle: String = "New",
        showsNewSessionOnEmpty: Bool = true,
        selectedSessionID: Binding<String?>,
        onNew: @escaping () -> Void,
        onDelete: @escaping (IndexSet, [Session]) -> Void,
        @ViewBuilder cell: @escaping (Session) -> Cell
    ) {
        self.open = open
        self.closed = closed
        self.openSectionTitle = openSectionTitle
        self.closedSectionTitle = closedSectionTitle
        self.navigationTitle = navigationTitle
        self.newButtonTitle = newButtonTitle
        self.showsNewSessionOnEmpty = showsNewSessionOnEmpty
        self._selectedSessionID = selectedSessionID
        self.onNew = onNew
        self.onDelete = onDelete
        self.cell = cell
    }

    var body: some View {
        List(selection: $selectedSessionID) {
            if !open.isEmpty {
                Section(openSectionTitle) {
                    ForEach(open, id: \.sessionID) { session in
                        cell(session).tag(session.sessionID as String?)
                    }
                    .onDelete { offsets in withAnimation { onDelete(offsets, open) } }
                }
            }
            if !closed.isEmpty {
                Section(closedSectionTitle) {
                    ForEach(closed, id: \.sessionID) { session in
                        cell(session).tag(session.sessionID as String?)
                    }
                    .onDelete { offsets in withAnimation { onDelete(offsets, closed) } }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(navigationTitle)
        .onAppear {
            if showsNewSessionOnEmpty && open.isEmpty && closed.isEmpty { onNew() }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    onNew()
                } label: {
                    Label(newButtonTitle, systemImage: "plus")
                }
                .labelStyle(.titleOnly)
            }
        }
    }
}

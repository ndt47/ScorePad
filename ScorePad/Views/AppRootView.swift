import SwiftUI
import SwiftData
import Observation

@Observable
final class AppNavigationState {
    var selectedModuleID: String? {
        didSet {
            UserDefaults.standard.set(selectedModuleID, forKey: DefaultsKey.selectedGameModuleID.rawValue)
            if oldValue != selectedModuleID { selectedSessionID = nil }
        }
    }
    var selectedSessionID: String?

    init() {
        selectedModuleID = UserDefaults.standard.string(forKey: DefaultsKey.selectedGameModuleID.rawValue)
    }
}

struct AppRootView: View {
    @Environment(GameRegistry.self) private var registry
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var navState = AppNavigationState()
    @State private var showingRoster = false

    private var selectedModule: (any GameModule)? {
        navState.selectedModuleID.flatMap { registry.module(id: $0) }
    }

    var body: some View {
        @Bindable var nav = navState
        NavigationSplitView {
            sidebar
        } content: {
            if let module = selectedModule {
                module.makeSessionListView(selectedSessionID: $nav.selectedSessionID)
            } else {
                GameTypeGridView { navState.selectedModuleID = $0 }
            }
        } detail: {
            if let module = selectedModule {
                module.makeDetailView(selectedSessionID: navState.selectedSessionID)
            } else {
                GameTypeGridView { navState.selectedModuleID = $0 }
            }
        }
        .sheet(isPresented: $showingRoster) {
            PlayerRosterView()
        }
        .task { migratePlayerProfiles() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { migratePlayerProfiles() }
        }
    }

    // Backfills PersonProfile records for all player names stored in existing game sessions.
    // Runs on foreground so CloudKit-synced data from other devices is picked up after sync settles.
    @MainActor
    private func migratePlayerProfiles() {
        do {
            var allNames: Set<String> = []
            let rubbers = try modelContext.fetch(FetchDescriptor<Rubber>())
            for rubber in rubbers { for player in rubber.players { allNames.insert(player.name) } }
            let milleGames = try modelContext.fetch(FetchDescriptor<MilleBornesGame>())
            for game in milleGames { for name in game.team1Players + game.team2Players { allNames.insert(name) } }
            let phase10Games = try modelContext.fetch(FetchDescriptor<Phase10Game>())
            for game in phase10Games { for name in game.players { allNames.insert(name) } }

            let existing = try modelContext.fetch(FetchDescriptor<PersonProfile>())
            let existingNames = Set(existing.map { $0.name.lowercased() })
            var inserted = false
            for name in allNames where !name.isEmpty && !existingNames.contains(name.lowercased()) {
                modelContext.insert(PersonProfile(name: name))
                inserted = true
            }
            if inserted { try modelContext.save() }
        } catch {}
    }

    private var sidebar: some View {
        @Bindable var nav = navState
        return List(selection: $nav.selectedModuleID) {
            ForEach(registry.moduleInfos) { info in
                Label(info.name, systemImage: info.systemImage)
                    .tag(info.id as String?)
            }
        }
        .navigationTitle("ScorePad")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingRoster = true
                } label: {
                    Label("Players", systemImage: "person.3")
                }
            }
        }
    }
}

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

    // Ensures PersonProfile records exist for every player across all game types and links
    // any unlinked PlayerRef/Player entries by name. Runs each foreground activation so
    // CloudKit-synced games landed after the previous launch are also picked up.
    @MainActor
    private func migratePlayerProfiles() {
        do {
            let rubbers     = try modelContext.fetch(FetchDescriptor<Rubber>())
            let milleGames  = try modelContext.fetch(FetchDescriptor<MilleBornesGame>())
            let phase10Games = try modelContext.fetch(FetchDescriptor<Phase10Game>())

            // Build a name → PersonProfile map, creating missing profiles as needed.
            var byName: [String: PersonProfile] = Dictionary(
                try modelContext.fetch(FetchDescriptor<PersonProfile>())
                    .map { ($0.name.lowercased(), $0) },
                uniquingKeysWith: { first, _ in first }
            )
            func profile(for name: String) -> PersonProfile {
                if let existing = byName[name.lowercased()] { return existing }
                let p = PersonProfile(name: name)
                modelContext.insert(p)
                byName[name.lowercased()] = p
                return p
            }

            // Ensure profiles exist for every name currently in game records.
            for r in rubbers     { for p in r.players          { _ = profile(for: p.name) } }
            for g in milleGames  { for r in g.team1Players + g.team2Players { _ = profile(for: r.name) } }
            for g in phase10Games { for r in g.players         { _ = profile(for: r.name) } }

            // Link any unlinked PlayerRef / Player entries.
            for game in milleGames {
                var t1 = game.team1Players; var t2 = game.team2Players; var changed = false
                for i in t1.indices where t1[i].profileID == nil { t1[i].profileID = profile(for: t1[i].name).id; changed = true }
                for i in t2.indices where t2[i].profileID == nil { t2[i].profileID = profile(for: t2[i].name).id; changed = true }
                if changed { game.team1Players = t1; game.team2Players = t2 }
            }
            for game in phase10Games {
                var refs = game.players; var changed = false
                for i in refs.indices where refs[i].profileID == nil { refs[i].profileID = profile(for: refs[i].name).id; changed = true }
                if changed { game.players = refs }
            }
            for rubber in rubbers {
                var players = rubber.players; var changed = false
                for i in players.indices where players[i].profileID == nil { players[i].profileID = profile(for: players[i].name).id; changed = true }
                if changed { rubber.players = players }
            }

            try modelContext.save()
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

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

    // Ensures PersonProfile records exist for every player and keeps cachedName values
    // fresh. Runs on every foreground activation to pick up CloudKit-synced games and
    // propagate PersonProfile renames to all linked PlayerRef records.
    //
    // Strategy: look up by profileID first (stable identity); fall back to cachedName
    // only for legacy records where profileID is nil or no longer matches a profile.
    @MainActor
    private func migratePlayerProfiles() {
        do {
            let allProfiles  = try modelContext.fetch(FetchDescriptor<PersonProfile>())
            let rubbers      = try modelContext.fetch(FetchDescriptor<Rubber>())
            let milleGames   = try modelContext.fetch(FetchDescriptor<MilleBornesGame>())
            let phase10Games = try modelContext.fetch(FetchDescriptor<Phase10Game>())

            var byID:   [UUID: PersonProfile] = Dictionary(allProfiles.map { ($0.id, $0) },
                                                            uniquingKeysWith: { f, _ in f })
            var byName: [String: PersonProfile] = Dictionary(allProfiles.map { ($0.name.lowercased(), $0) },
                                                              uniquingKeysWith: { f, _ in f })

            // Returns true if the ref was modified (needs to be written back).
            @discardableResult
            func resolve(_ ref: inout PlayerRef) -> Bool {
                if let id = ref.profileID, let p = byID[id] {
                    // Linked — refresh stale cachedName (picks up PersonProfile renames).
                    if ref.cachedName != p.name { ref.cachedName = p.name; return true }
                    return false
                }
                // profileID == nil (legacy) or no matching profile — fall back to name.
                let key = ref.cachedName.lowercased()
                if let p = byName[key] {
                    ref.profileID = p.id
                    byID[p.id] = p
                    return true
                }
                let p = PersonProfile(name: ref.cachedName)
                modelContext.insert(p)
                byID[p.id] = p; byName[key] = p
                ref.profileID = p.id
                return true
            }

            for game in milleGames {
                var t1 = game.team1Players; var t2 = game.team2Players; var changed = false
                for i in t1.indices { if resolve(&t1[i]) { changed = true } }
                for i in t2.indices { if resolve(&t2[i]) { changed = true } }
                if changed { game.team1Players = t1; game.team2Players = t2 }
            }
            for game in phase10Games {
                var refs = game.players; var changed = false
                for i in refs.indices { if resolve(&refs[i]) { changed = true } }
                if changed { game.players = refs }
            }
            for rubber in rubbers {
                var players = rubber.players; var changed = false
                for i in players.indices { if resolve(&players[i].ref) { changed = true } }
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

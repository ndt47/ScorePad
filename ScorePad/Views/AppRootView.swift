import SwiftUI
import Observation

@Observable
final class AppNavigationState {
    var selectedModule: GameModule? {
        didSet {
            UserDefaults.standard.set(selectedModule?.rawValue, forKey: DefaultsKey.selectedGameModuleID.rawValue)
            if oldValue != selectedModule { selectedSessionID = nil }
        }
    }
    var selectedSessionID: String?

    init() {
        if let raw = UserDefaults.standard.string(forKey: DefaultsKey.selectedGameModuleID.rawValue) {
            selectedModule = GameModule(rawValue: raw)
        }
    }
}

struct AppRootView: View {
    @Environment(GameRegistry.self) private var registry
    @State private var navState = AppNavigationState()
    @State private var showingRoster = false

    var body: some View {
        @Bindable var nav = navState
        NavigationSplitView {
            sidebar
        } content: {
            if let module = navState.selectedModule {
                module.sessionListView(selectedSessionID: $nav.selectedSessionID)
            } else {
                GameTypeGridView { navState.selectedModule = $0 }
            }
        } detail: {
            if let module = navState.selectedModule {
                module.detailView(selectedSessionID: navState.selectedSessionID)
            } else {
                GameTypeGridView { navState.selectedModule = $0 }
            }
        }
        .sheet(isPresented: $showingRoster) {
            PlayerRosterView()
        }
    }

    private var sidebar: some View {
        @Bindable var nav = navState
        return List(registry.modules, selection: $nav.selectedModule) { module in
            Label(module.name, systemImage: module.systemImage)
                .tag(module as GameModule?)
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

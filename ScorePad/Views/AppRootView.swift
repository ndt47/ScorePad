import SwiftUI
import Observation

@Observable
final class AppNavigationState {
    var selectedModuleID: String? {
        didSet {
            UserDefaults.standard.set(selectedModuleID, forKey: DefaultsKey.selectedGameModuleID.rawValue)
            // Reset session selection when switching games
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
    @State private var navState = AppNavigationState()
    @State private var showingRoster = false

    private var selectedModule: GameModuleDescriptor? {
        navState.selectedModuleID.flatMap { registry.module(id: $0) }
    }

    var body: some View {
        @Bindable var nav = navState
        NavigationSplitView {
            sidebar
        } content: {
            if let module = selectedModule {
                module.makeSessionListView($nav.selectedSessionID)
            } else {
                GameTypeGridView { navState.selectedModuleID = $0 }
            }
        } detail: {
            if let module = selectedModule {
                module.makeDetailView(navState.selectedSessionID)
            } else {
                GameTypeGridView { navState.selectedModuleID = $0 }
            }
        }
        .sheet(isPresented: $showingRoster) {
            PlayerRosterView()
        }
    }

    private var sidebar: some View {
        @Bindable var nav = navState
        return List(registry.modules, selection: $nav.selectedModuleID) { module in
            Label(module.name, systemImage: module.systemImage)
                .tag(module.id as String?)
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

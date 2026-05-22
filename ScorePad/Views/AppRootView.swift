import SwiftUI
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

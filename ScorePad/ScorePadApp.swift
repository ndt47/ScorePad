//
//  ScorePadApp.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import SwiftUI

@main
struct ScorePadApp: App {
    let store = Store()
    var body: some Scene {
        WindowGroup {
            RubberList(store: store)
        }
    }
}

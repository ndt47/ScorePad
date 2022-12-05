//
//  ScorePadApp.swift
//  ScorePad
//
//  Created by Nathan Taylor on 11/28/22.
//

import SwiftUI

@main
struct ScorePadApp: App {
    var body: some Scene {
        WindowGroup {
            RubberList(store: Store())
        }
    }
}

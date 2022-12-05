//
//  EnvironmentValues.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/1/22.
//

import SwiftUI

typealias PresentContract = (Contract) -> Void
private struct PresentContractKey: EnvironmentKey {
    static let defaultValue: PresentContract = { _ in return }
}


extension EnvironmentValues {
    var presentContract: PresentContract {
        get { self[PresentContractKey.self]}
        set { self[PresentContractKey.self] = newValue }
    }
}

extension View {
    func rubber(_ rubber: Rubber) -> some View {
        environmentObject(rubber)
    }
    
    func auction(_ auction: Auction) -> some View {
        environmentObject(auction)
    }
}



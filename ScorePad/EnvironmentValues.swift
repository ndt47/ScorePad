//
//  EnvironmentValues.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/1/22.
//

import SwiftUI

private struct RubberKey: EnvironmentKey {
    static let defaultValue = Rubber()
}

private struct DealerKey: EnvironmentKey {
    static let defaultValue = Position.north
}

private struct AuctionKey: EnvironmentKey {
    static let defaultValue = Auction()
}

typealias PresentContract = (Contract) -> Void
private struct PresentContractKey: EnvironmentKey {
    static let defaultValue: PresentContract = { _ in return }
}


extension EnvironmentValues {
    var rubber: Rubber {
        get { self[RubberKey.self] }
        set { self[RubberKey.self] = newValue }
    }

    var dealer: Position {
        get { self[DealerKey.self]}
        set { self[DealerKey.self] = newValue }
    }
    
    var auction: Auction {
        get { self[AuctionKey.self]}
        set { self[AuctionKey.self] = newValue }
    }
    
    var presentContract: PresentContract {
        get { self[PresentContractKey.self]}
        set { self[PresentContractKey.self] = newValue }
    }
}

extension View {
    func rubber(_ rubber: Rubber) -> some View {
        environment(\.rubber, rubber)
            .environmentObject(rubber)
    }
    
    func dealer(_ dealer: Position) -> some View {
        environment(\.dealer, dealer)
    }
    
    func auction(_ auction: Auction) -> some View {
        environment(\.auction, auction)
    }
}



import Foundation

// Each safety card is a named struct rather than a count so the UI can disable the
// matching card for the opposing team — a specific card can only be held by one team per hand.
struct MilleBornesSafetyState: Codable, Equatable {
    var played: Bool = false
    var coupFourre: Bool = false
}

// Shut-out is intentionally absent here. It requires knowing the opposing team's
// mile total, which this struct doesn't have. It lives on MilleBornesHand instead.
struct MilleBornesTeamScore: Codable, Equatable {
    var cards25: Int = 0
    var cards50: Int = 0
    var cards75: Int = 0
    var cards100: Int = 0
    var cards200: Int = 0  // max 2 per hand

    var rightOfWay    = MilleBornesSafetyState()  // 🚒
    var punctureProof = MilleBornesSafetyState()  // 🛞
    var drivingAce    = MilleBornesSafetyState()  // 🏎️
    var extraTank     = MilleBornesSafetyState()  // ⛽

    // Extension must be declared at the table at exactly 700 miles (2-player only).
    var usedExtension: Bool = false
    var delayedAction: Bool = false

    var totalMiles: Int {
        cards25 * 25 + cards50 * 50 + cards75 * 75 + cards100 * 100 + cards200 * 200
    }

    var safeties: Int {
        [rightOfWay, punctureProof, drivingAce, extraTank].filter(\.played).count
    }
    var coupsFourres: Int {
        [rightOfWay, punctureProof, drivingAce, extraTank].filter(\.coupFourre).count
    }

    var allFourSafeties: Bool { safeties == 4 }

    // Both teams can earn an extension bonus: +400 for the team that reaches 1000,
    // +200 for a team that called extension but didn't win the trip.
    var extensionBonus: Int {
        guard usedExtension else { return 0 }
        return totalMiles == 1000 ? 400 : 200
    }

    // 2-player rule: trip ends at 700 unless extension was called by either team, then at 1000.
    // 4-player rule: trip always ends at 1000; extension is not available.
    // Callers with cross-team visibility should pass extensionCalled: team1.usedExtension || team2.usedExtension
    // so the non-calling team also plays to 1000 when the opponent declares extension.
    func tripCompleted(isTwoPlayerGame: Bool, extensionCalled: Bool = false) -> Bool {
        isTwoPlayerGame ? (totalMiles == 700 && !(usedExtension || extensionCalled)) || totalMiles == 1000
                        : totalMiles == 1000
    }

    func safeTrip(isTwoPlayerGame: Bool, extensionCalled: Bool = false) -> Bool {
        tripCompleted(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled) && cards200 == 0
    }

    func handScore(isTwoPlayerGame: Bool, extensionCalled: Bool = false) -> Int {
        let tc = tripCompleted(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled)
        let st = safeTrip(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled)
        return totalMiles
            + safeties * 100
            + coupsFourres * 300
            + (tc              ? 400 : 0)
            + (allFourSafeties ? 300 : 0)
            + (st              ? 300 : 0)
            + extensionBonus
            + (delayedAction   ? 300 : 0)
    }

    func scoreLines(isTwoPlayerGame: Bool, extensionCalled: Bool = false) -> [MilleBornesScoreLine] {
        let tc = tripCompleted(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled)
        let st = safeTrip(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled)
        var lines: [MilleBornesScoreLine] = []
        if totalMiles > 0 {
            lines.append(MilleBornesScoreLine(label: "Miles", value: totalMiles))
        }
        if safeties > 0 {
            let label = safeties == 1 ? "Safety" : "Safety ×\(safeties)"
            lines.append(MilleBornesScoreLine(label: label, value: safeties * 100))
        }
        if coupsFourres > 0 {
            let label = coupsFourres == 1 ? "Coup Fourré" : "Coup Fourré ×\(coupsFourres)"
            lines.append(MilleBornesScoreLine(label: label, value: coupsFourres * 300))
        }
        if tc              { lines.append(MilleBornesScoreLine(label: "Trip",             value: 400)) }
        if allFourSafeties { lines.append(MilleBornesScoreLine(label: "All 4 Safeties",   value: 300)) }
        if st              { lines.append(MilleBornesScoreLine(label: "Safe Trip",        value: 300)) }
        if usedExtension   { lines.append(MilleBornesScoreLine(label: "Called Extension", value: extensionBonus)) }
        if delayedAction   { lines.append(MilleBornesScoreLine(label: "Delayed Action",   value: 300)) }
        return lines
    }
}

struct MilleBornesScoreLine: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

import Foundation

struct MilleBornesSafetyState: Codable, Equatable {
    var played: Bool = false
    var coupFourre: Bool = false
}

struct MilleBornesTeamScore: Codable, Equatable {
    var cards25: Int = 0
    var cards50: Int = 0
    var cards75: Int = 0
    var cards100: Int = 0
    var cards200: Int = 0  // max 2 per hand

    // One state per safety card — each card can only go to one team per hand
    var rightOfWay    = MilleBornesSafetyState()  // 🚒
    var punctureProof = MilleBornesSafetyState()  // 🛞
    var drivingAce    = MilleBornesSafetyState()  // 🏎️
    var extraTank     = MilleBornesSafetyState()  // ⛽

    var usedExtension: Bool = false  // must be declared at the table when reaching 700 mi
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

    // Extension bonus: +400 if the calling team reaches 1000, +200 if they called but opponent won.
    var extensionBonus: Int {
        guard usedExtension else { return 0 }
        return totalMiles == 1000 ? 400 : 200
    }

    // 2-player: win at 700 (or 1000 with extension). 4-player: win at 1000.
    func tripCompleted(isTwoPlayerGame: Bool) -> Bool {
        isTwoPlayerGame ? (totalMiles == 700 && !usedExtension) || totalMiles == 1000
                        : totalMiles == 1000
    }

    func safeTrip(isTwoPlayerGame: Bool) -> Bool {
        tripCompleted(isTwoPlayerGame: isTwoPlayerGame) && cards200 == 0
    }

    func handScore(isTwoPlayerGame: Bool) -> Int {
        let tc = tripCompleted(isTwoPlayerGame: isTwoPlayerGame)
        let st = safeTrip(isTwoPlayerGame: isTwoPlayerGame)
        return totalMiles
            + safeties * 100
            + coupsFourres * 300
            + (tc              ? 400 : 0)
            + (allFourSafeties ? 300 : 0)
            + (st              ? 300 : 0)
            + extensionBonus
            + (delayedAction   ? 300 : 0)
    }

    func scoreLines(isTwoPlayerGame: Bool) -> [MilleBornesScoreLine] {
        let tc = tripCompleted(isTwoPlayerGame: isTwoPlayerGame)
        let st = safeTrip(isTwoPlayerGame: isTwoPlayerGame)
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

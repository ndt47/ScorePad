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

    // Trip completed means this team WON the hand.
    // At 700 miles with extension called, the hand continues — not a win yet.
    var tripCompleted: Bool { (totalMiles == 700 && !usedExtension) || totalMiles == 1000 }
    var allFourSafeties: Bool { safeties == 4 }
    var safeTrip: Bool { tripCompleted && cards200 == 0 }

    // Extension bonus: +400 if the calling team reaches 1000, +200 if they called but opponent won.
    var extensionBonus: Int {
        guard usedExtension else { return 0 }
        return totalMiles == 1000 ? 400 : 200
    }

    var handScore: Int {
        totalMiles
        + safeties * 100
        + coupsFourres * 300
        + (tripCompleted   ? 400 : 0)
        + (allFourSafeties ? 300 : 0)
        + (safeTrip        ? 300 : 0)
        + extensionBonus
        + (delayedAction   ? 300 : 0)
    }

    var scoreLines: [MilleBornesScoreLine] {
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
        if tripCompleted   { lines.append(MilleBornesScoreLine(label: "Trip",             value: 400)) }
        if allFourSafeties { lines.append(MilleBornesScoreLine(label: "All 4 Safeties",   value: 300)) }
        if safeTrip        { lines.append(MilleBornesScoreLine(label: "Safe Trip",        value: 300)) }
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

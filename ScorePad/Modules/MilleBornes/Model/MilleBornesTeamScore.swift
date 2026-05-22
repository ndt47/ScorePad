import Foundation

struct MilleBornesTeamScore: Codable, Equatable {
    var cards25: Int = 0
    var cards50: Int = 0
    var cards75: Int = 0
    var cards100: Int = 0
    var cards200: Int = 0  // max 2 per hand

    var safeties: Int = 0       // total safety cards played (0–4)
    var coupsFourres: Int = 0   // subset played as coup fourré (0–safeties)

    var tripCompleted: Bool = false
    var allFourSafeties: Bool = false
    var usedExtension: Bool = false
    var shutOut: Bool = false
    var delayedAction: Bool = false

    var totalMiles: Int {
        cards25 * 25 + cards50 * 50 + cards75 * 75 + cards100 * 100 + cards200 * 200
    }

    // Auto-detected: no 200-mile cards used when trip was completed
    var safeTrip: Bool { tripCompleted && cards200 == 0 }

    var handScore: Int {
        totalMiles
        + safeties * 100
        + coupsFourres * 300
        + (tripCompleted    ? 400 : 0)
        + (allFourSafeties  ? 300 : 0)
        + (safeTrip         ? 300 : 0)
        + (usedExtension    ? 200 : 0)
        + (shutOut          ? 500 : 0)
        + (delayedAction    ? 300 : 0)
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
        if tripCompleted  { lines.append(MilleBornesScoreLine(label: "Trip",          value: 400)) }
        if allFourSafeties { lines.append(MilleBornesScoreLine(label: "All 4 Safeties", value: 300)) }
        if safeTrip       { lines.append(MilleBornesScoreLine(label: "Safe Trip",     value: 300)) }
        if usedExtension  { lines.append(MilleBornesScoreLine(label: "Extension",     value: 200)) }
        if shutOut        { lines.append(MilleBornesScoreLine(label: "Shut Out",      value: 500)) }
        if delayedAction  { lines.append(MilleBornesScoreLine(label: "Delayed Action",value: 300)) }
        return lines
    }
}

struct MilleBornesScoreLine: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

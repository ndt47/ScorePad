# Uno module — design

Status: **v1 implemented** (decisions made 2026-09-14; built on branch `modules/uno`). Interactive mockups: [`uno-mockups.html`](uno-mockups.html) — open it in a browser; the hand-entry mockups are live.

## Scope for v1

- One **Uno** tile in the game grid. The edition is chosen when a game is created: **Uno Classic** or **Uno Flip**.
- Both official scoring methods, chosen per game: **winner collects** (default) and **points against**.
- Hand entry is **Quick Total**: one "points left" field per opponent, with a **Count** button beside each field. Count opens the **Card Pad**, where you tap the cards in that player's hand; the total goes back into the field. (Nathan: "it's easy to forget individual card values.")
- The score sheet depends on the scoring method: **race bars + hand log** for winner collects, a **ledger grid** for points against.

Deferred to later updates:

- Partnership (2-v-2) play.
- Other editions. Uno Attack and Uno All Wild only need a card-value table and a Card Pad layout. Show 'Em No Mercy also needs knock-outs modelled (a player holding 25+ cards is out; whoever knocked them out gets 250), and it plays to 1,000.

## Rules the module encodes

The player who goes out ends the hand. Cards left in every other hand are counted.

**Winner collects** (official default): the player who went out scores the total of everyone else's cards. First to the target (500) wins.
**Points against** (official alternative): each player scores the cards left in their own hand. When anyone reaches the target, the lowest total wins.

If the last card played was a draw card, the next player draws those cards before anyone counts. The hand-entry sheet shows this as a hint.

In Flip, cards are counted by the side that was **face up when the hand ended**; a light-side-only card such as Draw One is worth nothing if the hand ended on the dark side. Each Flip hand records which side it ended on.

### Card values

| Card | Classic | Flip — light | Flip — dark |
|---|---|---|---|
| Number cards | face value (0–9) | face value (1–9) | face value (1–9) |
| Draw One | — | 10 | — |
| Draw Two | 20 | — | — |
| Draw Five | — | — | 20 |
| Skip | 20 | 20 | — |
| Skip Everyone | — | — | 30 |
| Reverse | 20 | 20 | 20 |
| Flip | — | 20 | 20 |
| Wild Shuffle Hands / Wild Customizable | 40 | — | — |
| Wild | 50 | 40 | 40 |
| Wild Draw Four | 50 | — | — |
| Wild Draw Two | — | 50 | — |
| Wild Draw Color | — | — | 60 |

Sources: official Mattel rules as summarised by unorules.com, UltraBoardGames and Asmodee UK.

## Data model

Follows the player system described in `CLAUDE.md` ("Players"): seats are `PlayerRef`s, and new-game forms use `PlayerPickerField` + `PlayerSlot`.

```swift
enum UnoEdition: String, Codable, CaseIterable { case classic, flip }
enum UnoScoring: String, Codable, CaseIterable { case winnerCollects, pointsAgainst }
enum UnoSide: String, Codable { case light, dark }

@Model final class UnoGame {
    var id = UUID()
    var dateCreated = Date.now
    var lastModified = Date.now
    var players: [PlayerRef] = []
    var edition = UnoEdition.classic
    var scoring = UnoScoring.winnerCollects
    var targetScore = 500
    var startingDealerIndex = 0
    var hands: [UnoHand] = []

    // Computed, never stored:
    var currentDealerIndex: Int          // (startingDealerIndex + hands.count) % players.count
    func cumulativeScore(for player: Int) -> Int
        // winnerCollects: sum of handValue over hands the player went out in
        // pointsAgainst:  sum of the player's own pointsLeft
    var isFinished: Bool                 // anyone's cumulative score ≥ targetScore
    var winnerIndices: [Int]             // highest score (winnerCollects) or lowest (pointsAgainst); several on a tie
}

struct UnoHand: Codable, Identifiable, Equatable {
    var id = UUID()
    var date = Date.now
    var wentOutIndex: Int
    var side = UnoSide.light             // meaningful only for Flip
    var pointsLeft: [Int]                // one per player; the player who went out has 0
    var handValue: Int { pointsLeft.reduce(0, +) }
}
```

- A hand stores **points per player**, not individual cards. The Card Pad is only a way to arrive at a number, and players who count their own hands can type the total directly.
- Card values are **data**: `UnoEdition.cards(side:) -> [UnoCard]`, where `UnoCard` has a label, a colour and a point value. The Card Pad draws its keys from the same table, so a new edition means adding one table.
- `UnoModule.updatePlayerRefs` walks `UnoGame.players`, the same way `Phase10Module` does. `modelTypes` is `[UnoGame.self]`. With the module added to `ScorePadApp.modules`, the schema, rename, merge and delete checks all include Uno games.

## Screens

### New Game

Uses Phase 10's layout (`NewPhase10Game`):

- Edition picker: Uno / Uno Flip (segmented).
- Players: 2–10, reorderable and removable, with colour dots. `PlayerSlot` validation blocks Start until every seat is named and each is a distinct player.
- Scoring: winner collects / points against. "Play to" stepper, default 500.
- Starting dealer, with Randomize; the choice is tracked by seat ID, as in Phase 10.

Player colours: red, yellow, green, blue (the Uno colours), then the Phase 10 extended palette for players 5–10.

### Hand entry: Quick Total + Card Pad

The sheet is titled "Hand N" and has these sections:

- **Went out:** player chips; exactly one must be selected.
- **Hand ended on** (Flip only): Light / Dark, segmented.
- **Points left in hand:** one row per player except the one who went out. Each row has a number field (text-backed, so a value typed just before Save isn't lost) and a **Count** button.
- **Footer:** the draw-card hint, and a total bar reading "*Name* collects *N*" (winner collects) or "Hand total *N*" (points against).

**Count** opens the Card Pad for that player:

- Number keys, and action-card keys in the colours of the edition and side.
- The cards tapped so far appear in a tray; tapping a card in the tray removes it.
- A running total, with **Done** writing it into the field and **Cancel** leaving the field alone.
- In Flip, the keys follow the side chosen in the sheet: the dark side uses the dark palette (pink, teal, orange, purple).

Tapping a hand in the score sheet opens this sheet to edit it, as in Phase 10.

### Score sheet

The layout depends on the game's scoring method:

- **Winner collects: race + hand log.**
  - A bar per player running toward a dashed target line, sorted by score.
  - Below, one row per hand, newest first: "*Name* went out … +N", with the breakdown underneath ("Bob 34 · Cara 12 · Dan 50") and a light/dark marker on Flip hands.
- **Points against: ledger grid.** Phase 10's layout: a pinned header with colour bar, name, dealer badge, running total and a progress bar toward the target, then one row per hand with each player's points.

### List cell

Players, the edition badge ("Flip"), each player's total, and a trophy on the winner once the game is finished.

## Implementation plan

1. `Modules/Uno/Model`:
   - `UnoGame`, `UnoHand`, the edition/scoring/side enums, and the card-value tables.
   - Tests for scoring in both methods, finishing, winner selection, dealer rotation, and card-table totals (for example, a dark-side Wild Draw Color is 60 while a light-side Draw One is 10).
2. `UnoModule` + `UnoGame+GameSession`: register in `ScorePadApp.modules`.
3. New Game sheet.
4. Hand entry sheet (Quick Total), then the Card Pad sheet.
5. Score sheets: race + log and ledger grid, with the detail view choosing between them by scoring method.
6. List cell and previews. Check the iOS and macOS builds.

## Open questions

Both were built as proposed; confirm or change:

- **Ties** at the end of a game: players tied on the best total are all shown as winners (`UnoGame.winnerIndices`).
- **Finished games** take no more hands: Add Hand is disabled, matching Phase 10. Existing hands can still be edited.

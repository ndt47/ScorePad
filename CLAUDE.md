# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

ScorePad is a multi-game scoring app for iOS and macOS, built with SwiftUI and SwiftData. It supports multiple board/card games via a modular plug-in architecture. Current modules: **Bridge**, **Mille Bornes**, **Phase 10** and **Uno** (Classic and Flip).

## Tools

**Always use the Xcode MCP tools** (`mcp__xcode__*`) for building, testing, and project file operations — never raw `xcodebuild` CLI or shell scripts. Key tools:
- `mcp__xcode__BuildProject` — build and surface errors
- `mcp__xcode__RunAllTests` / `mcp__xcode__RunSomeTests` — run tests
- `mcp__xcode__XcodeLS` / `mcp__xcode__XcodeRead` / `mcp__xcode__XcodeWrite` — project-aware file ops (auto-adds new files to the Xcode project)
- `mcp__xcode__XcodeMV` / `mcp__xcode__XcodeRM` / `mcp__xcode__XcodeMakeDir` — rename/delete/create groups

## Build & Test

Build and run via Xcode. There is no separate build script.

To run all tests (fallback if MCP unavailable):
```bash
xcodebuild test -scheme ScorePad -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Git Workflow

Always create a feature branch at the start of a session. Never commit directly to `main`. Create a PR when a logical unit of work is ready.

## Project Structure

```
ScorePad/
├── Core/                        # GameModule protocol, GameRegistry, PersonProfile, shared UI
├── Views/                       # App-level shared views: AppRootView, GameTypeGridView, Rule, WinnerBadge
└── Modules/
    ├── Bridge/
    │   ├── BridgeModule.swift
    │   ├── Rubber+GameSession.swift
    │   ├── Model/               # Rubber, Auction, Contract, Score, etc.
    │   ├── Views/               # RubberView, AuctionView, RubberListCell, etc.
    │   └── Tests/               # AuctionTests, ContractTests, ScoreTests, etc.
    ├── MilleBornes/
    │   ├── MilleBornesModule.swift
    │   ├── MilleBornesGame+GameSession.swift
    │   ├── Model/               # MilleBornesGame, MilleBornesHand, MilleBornesTeamScore
    │   ├── Views/               # MilleBornesGameView, MilleBornesHandView, MilleBornesListCell, etc.
    │   └── Tests/               # MilleBornesTests
    ├── Phase10/                 # same layout
    └── Uno/                     # same layout; design in docs/design/uno.md
```

Tests live **inside each module's `Tests/` folder**, co-located with the source.

## Module System

Navigation is a 3-column `NavigationSplitView`: game-type sidebar | session list | session detail. Cold launch with no selection shows `GameTypeGridView`.

Each game module conforms to `GameModule` (protocol):

```swift
protocol GameModule {
    var id: String { get }
    var name: String { get }
    var systemImage: String { get }
    var modelTypes: [any PersistentModel.Type] { get }
    // Visit each stored session's players in seat order; write back changed refs; don't save.
    @MainActor func updatePlayerRefs(in context: ModelContext, _ body: (inout [PlayerRef]) -> Void) throws
    func sessionListView(selectedSessionID: Binding<String?>) -> some View
    func detailView(selectedSessionID: String?) -> some View
}
```

Modules are registered by adding the instance to `ScorePadApp.modules`. `ScorePadApp.schema` is built from `PersonProfile` plus every module's `modelTypes`, and `PlayerProfileService` reaches each module's players through `updatePlayerRefs` — so registration alone wires a module into storage, rename, merge and delete checks.

### Adding a New Game Module

1. Create `Modules/GameName/` with the folder structure above
2. Implement `GameModule` in `GameNameModule.swift`, including `updatePlayerRefs`
3. Add `@Model` root class; store players as `[PlayerRef]` and hand data as `Codable` structs
4. Add conformance to `GameSession` (provides `fetchDescriptor`, list cell, new-session view); the new-session view collects players with `PlayerPickerField` + `PlayerSlot`
5. Add the module to `ScorePadApp.modules`

## Architecture

### Players (`ScorePad/Core/Players/`)

- `PersonProfile` (`@Model`) — one real person on the shared roster: `name` (what games show), optional `lastName`, `aliases`. Names and aliases are **not unique**; `fullName` and aliases tell same-named people apart.
- `PlayerRef` (`Codable`) — a game seat: `profileID` (the identity) + `cachedName` (display cache, kept in sync by `PlayerProfileService`). Build a game's seats with `PlayerRef.seats(for:)`, which shows players sharing a first name with their last initial ("Bob S.").
- `PlayerSlot` + `PlayerPickerField` — new-game seats. The field suggests roster players by full name/alias plus a "New player" row; `PlayerSlot.problem(with:roster:)` blocks Start/Save until every seat is named and is a distinct, unambiguous player; `PlayerSlot.resolve` creates profiles only on commit.
- `PlayerProfileService` — rename and last name (both re-sync affected games' display names), aliases, merge (refused if the players shared a game), delete (refused if the player is in any game), game counts, and an ID-only `refreshCachedNames()` run on launch/foreground that only replaces names the player is known by. Every mutation saves pending edits first, checks, then applies, so a refusal never discards unsaved work.

The app is pre-release: stored formats carry no backward-compatibility code.

### Shared Views (`ScorePad/Views/`)

- `Rule` — a styled divider (`.vertical` or `.horizontal`)
- `WinnerBadge` — trophy + "Winner" label; `showLabel: Bool = true` for the icon-only variant used in list cells

### Bridge Module

#### Data Flow

Two `@Model` classes: `Rubber` and `Auction`. Everything else is a `Codable` struct/enum stored inside them.

```
Rubber
  └── [AuctionResult]
        ├── .missDeal(Position)
        ├── .pass(Auction)
        └── .contract(Auction, Contract)
```

`AuctionResult` is the unit of history. All derived state (games, scores, vulnerability) is computed from `Rubber.history` — never stored.

#### Scoring

- `Score` enum: `.bid` (under-the-line), `.over`, `.under`, `.slam`, `.honors`, `.rubber` (over-the-line)
- `Contract.scores` → `[Score]` for a single hand; `[AuctionResult].scores` aggregates
- `Points` separates `above`/`below` the line
- `Game` enum: `.none`, `.partial`, `.complete(Team, range)`, `.rubber(Team, range)` — via `Collection<AuctionResult>.games`
- Vulnerability computed from completed games; `Rubber._adjustContracts(from:)` recalculates the `vulnerable` snapshot on all subsequent contracts when history is edited

#### Teams and Positions

- `Team.we` = N+S; `Team.they` = E+W
- `Position` cycles N→E→S→W; `.team` gives owning team; `.dummy` gives partner

#### Auction State Machine

`Auction` (@Model) validates calls in `addCall(_:)`:
- Bids must be higher than the last bid
- Doubles only against opposing team's bid; redoubles only against opposing double
- Closes after four passes, or one non-pass + three passes
- `declarer` = first player on the declaring team who bid the trump suit (not the last bidder)

#### View Layer

`@EnvironmentObject` passes `Rubber` and `Auction` down the hierarchy. `presentContract: (Contract) -> Void` environment key opens the edit sheet from a tapped score row.

Navigation: `RubberList` → `RubberView` → `AuctionView` (sheet).
`RubberView`: `OverTheLine` (scrolls up, newest at bottom) + `UnderTheLine` (per-game `GameView`).
`Score` enum conforms to `View` directly — each case renders itself.

### Mille Bornes Module

#### Data Model

- `MilleBornesGame` (`@Model`) — root session; `team1Players: [PlayerRef]`, `team2Players: [PlayerRef]`, `hands: [MilleBornesHand]`
  - `isTwoPlayerGame`: `team1Players.count <= 1`
  - `isFinished`: either team ≥ 5000 cumulative points
  - `cumulativeScore(team:)` / `winningTeam` are computed from hands
- `MilleBornesHand` (`Codable`, `Identifiable`) — one hand; `team1: MilleBornesTeamScore`, `team2: MilleBornesTeamScore`
  - `team1ShutOut(isTwoPlayerGame:)` / `team2ShutOut(isTwoPlayerGame:)` — computed (opponent has 0 miles and this team completed the trip)
- `MilleBornesTeamScore` (`Codable`) — per-team per-hand data; all scoring is **computed, not stored**

#### Scoring Rules

Miles are tracked as card counts (25/50/75/100/200); `totalMiles` is derived. Safeties are individual `MilleBornesSafetyState(played:, coupFourre:)` structs.

| Item | Points |
|---|---|
| Miles driven | face value |
| Each Safety played | +100 |
| Each Coup Fourré | +300 (on top of the safety 100) |
| Trip Completed | +400 |
| All 4 Safeties | +300 |
| Safe Trip (no 200-mi cards) | +300 |
| Called Extension (caller wins at 1000) | +400 |
| Called Extension (caller loses) | +200 |
| Shut Out (opponents have 0 miles) | +500 — computed on `MilleBornesHand`, not stored on team score |
| Delayed Action | +300 |

Mile limits: **2-player** max 700 (1000 with called extension); **4-player** max 1000 (no extension). `tripCompleted(isTwoPlayerGame:)` and `handScore(isTwoPlayerGame:)` take a Bool parameter. `isTwoPlayerGame` is also propagated via `EnvironmentValues.isTwoPlayerGame` to all views.

#### View Layer

`@EnvironmentObject var game: MilleBornesGame` flows through the view hierarchy. Environment keys:
- `\.isTwoPlayerGame` — read by `TeamScoreEditor`, `MilleBornesHandRow`, `TeamScoreColumn`
- `\.presentHand: (MilleBornesHand) -> Void` — tapping a hand row in `MilleBornesGameView` opens `MilleBornesHandView` in edit mode

### Uno Module

Design record: `docs/design/uno.md` (mockups: `docs/design/uno-mockups.html`).

- `UnoGame` (`@Model`) — `players: [PlayerRef]`, `edition` (`.classic` / `.flip`), `scoring` (`.winnerCollects` / `.pointsAgainst`), `targetScore` (default 500), `startingDealerIndex`, `hands: [UnoHand]`
  - `score(for:in:)` / `cumulativeScore(for:)`: winner collects — whoever went out scores the hand's total; points against — each player scores their own points left
  - `isFinished`: anyone reaches `targetScore`; `winnerIndices`: highest (winner collects) or lowest (points against) total, several on a tie
- `UnoHand` (`Codable`) — `wentOutIndex`, `side` (Flip only), `pointsLeft: [Int]` per player (0 for whoever went out). Hands store points, not cards.
- Card values are data: `UnoEdition.cards(side:) -> [UnoCard]`. Flip hands are counted by the side face up when the hand ended. The Card Pad (`UnoCardPad`) draws its keys from the same table, so a new edition is one more table.
- Views: `UnoHandView` (Quick Total per opponent, each with a Count button opening `UnoCardPad`); `UnoGameView` picks `UnoRaceSheet` (winner collects) or `UnoLedgerSheet` (points against).

## Key Design Decisions

- Each module's `@Model` is the single source of truth. All derived state is computed, not stored.
- `Codable` hand data is embedded in the `@Model` class rather than stored as separate `@Model` objects (keeps the graph simple).
- CloudKit sync is enabled (`iCloud.com.nathan47.ScorePad`).
- `Rubber` and `Auction` implement `Codable` manually alongside `@Model` for import/export.
- Platform differences (toolbar placement, form style) are wrapped in `#if os(iOS)` / `#else` blocks. On macOS, `Form` uses `.formStyle(.grouped)`.

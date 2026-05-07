# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

ScorePad is a rubber bridge scoring app for iOS and macOS, built with SwiftUI and SwiftData. It tracks the full lifecycle of a rubber bridge game: auction → contract → result → scoring.

## Build & Test

Build and run via Xcode. There is no separate build script.

To run tests from the command line:
```bash
xcodebuild test -scheme ScorePad -destination 'platform=iOS Simulator,name=iPhone 16'
```

To run a single test:
```bash
xcodebuild test -scheme ScorePad -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing ScorePadTests/AuctionTests/testBidding
```

## Architecture

### Data Flow

The app uses SwiftData for persistence with two `@Model` classes: `Rubber` and `Auction`. Everything else (`Contract`, `Score`, `Call`, `AuctionResult`, etc.) is a plain `struct` or `enum` stored as `Codable` inside those models.

The core data hierarchy is:

```
Rubber
  └── [AuctionResult]      (history of all hands)
        ├── .missDeal(Position)
        ├── .pass(Auction)
        └── .contract(Auction, Contract)
```

`AuctionResult` is the unit of history. Computing games, scores, and vulnerability all derives from `Rubber.history` by walking this array.

### Scoring Model

Scoring is computed lazily from history rather than stored — this is intentional so that editing a past contract recalculates everything downstream.

- `Score` enum: cases are `.bid` (under-the-line), `.over`, `.under`, `.slam`, `.honors`, `.rubber` (over-the-line)
- `Contract.scores` produces the `[Score]` for a single hand
- `[AuctionResult].scores` aggregates scores for a sequence of hands
- `Points` struct separates `above` and `below` the line
- `Game` enum tracks game state: `.none`, `.partial`, `.complete(Team, range)`, `.rubber(Team, range)` — computed via `Collection<AuctionResult>.games`

Vulnerability is computed from completed games and affects undertrick/overtrick scoring. When a contract is edited, `Rubber._adjustContracts(from:)` recalculates the `vulnerable` flag on all subsequent contracts.

### Teams and Positions

- `Team.we` = North + South; `Team.they` = East + West
- `Position` cycles N→E→S→W with `.next`/`.previous`; `.team` gives the owning team; `.dummy` gives the partner

### Auction State Machine

`Auction` is a `@Model` class that validates calls. Key rules enforced in `addCall(_:)`:
- Bids must be higher than the last bid (level or suit)
- Doubles only against the opposing team's bid
- Redoubles only against the opposing team's double
- Auction closes after: four passes (passed hand), or one non-pass followed by three passes

`Auction.declarer` is the first player on the declaring team who bid the contract suit — not necessarily the last bidder.

### View Layer

Views use `@EnvironmentObject` to pass `Rubber` and `Auction` down the hierarchy. The environment key `presentContract: (Contract) -> Void` is used to open the contract edit sheet from a tapped score row.

Navigation: `RubberList` (split view) → `RubberView` → `AuctionView` (sheet).

`RubberView` contains `OverTheLine` (scrolls up, newest at bottom) and `UnderTheLine` (per-game `GameView` with dividers between games). Both read directly from `@EnvironmentObject var rubber: Rubber`.

The `Score` enum conforms to `View` directly — each score case renders itself.

### Multi-Platform

The codebase targets both iOS and macOS. Platform-specific toolbar item placement is wrapped in `#if os(iOS)` / `#else` blocks throughout the views.

## Key Design Decisions

- `Rubber.history` is the single source of truth. All derived state (games, scores, vulnerability) is computed from it.
- `Contract` stores `vulnerable` as a snapshot at the time of entry, but `_adjustContracts` corrects this when history is edited.
- `Auction` is persisted as a `@Model` because it can be large and is referenced from `Contract`. All other types are `Codable` values embedded in `Rubber`.
- CloudKit sync is enabled (`iCloud.com.nathan47.ScorePad` container).
- `Rubber` and `Auction` both implement `Codable` manually alongside their `@Model` conformance for import/export scenarios.

import SwiftUI

typealias PresentHand = (MilleBornesHand) -> Void

private struct PresentHandKey: EnvironmentKey {
    static let defaultValue: PresentHand = { _ in }
}

private struct IsTwoPlayerGameKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var presentHand: PresentHand {
        get { self[PresentHandKey.self] }
        set { self[PresentHandKey.self] = newValue }
    }
    var isTwoPlayerGame: Bool {
        get { self[IsTwoPlayerGameKey.self] }
        set { self[IsTwoPlayerGameKey.self] = newValue }
    }
}

// MARK: - Hand Row

struct MilleBornesHandRow: View {
    var hand: MilleBornesHand
    @Environment(\.presentHand) var present
    @Environment(\.isTwoPlayerGame) var isTwoPlayerGame

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            TeamScoreColumn(score: hand.team1, shutOut: hand.team1ShutOut(isTwoPlayerGame: isTwoPlayerGame), extensionCalled: hand.extensionCalled)
            TeamScoreColumn(score: hand.team2, shutOut: hand.team2ShutOut(isTwoPlayerGame: isTwoPlayerGame), extensionCalled: hand.extensionCalled)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { present(hand) }
    }
}

struct MilleBornesHandRow_Previews: PreviewProvider {
    static var hand: MilleBornesHand {
        var h = MilleBornesHand()
        h.team1.cards100 = 6; h.team1.cards50 = 2  // 700 miles → tripCompleted auto
        h.team1.rightOfWay.played = true
        h.team1.punctureProof = MilleBornesSafetyState(played: true, coupFourre: true)
        h.team2.cards100 = 3; h.team2.cards50 = 2
        h.team2.extraTank.played = true
        return h
    }

    static var previews: some View {
        ZStack {
            Rectangle()
                .fill(.separator)
                .frame(width: 0.5)
            MilleBornesHandRow(hand: hand)
                .environment(\.isTwoPlayerGame, false)
                .padding(.vertical, 4)
        }
        .frame(height: 160)
        .padding(.horizontal)
    }
}

// MARK: - Team Score Column

struct TeamScoreColumn: View {
    var score: MilleBornesTeamScore
    var shutOut: Bool
    var extensionCalled: Bool
    @Environment(\.isTwoPlayerGame) var isTwoPlayerGame

    private var totalScore: Int { score.handScore(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled) + (shutOut ? 500 : 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Spacer(minLength: 0)
            ForEach(score.scoreLines(isTwoPlayerGame: isTwoPlayerGame, extensionCalled: extensionCalled)) { line in
                HStack {
                    Text(line.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(line.value.formatted(.number.grouping(.never)))
                        .font(.caption)
                        .fontDesign(.monospaced)
                }
            }
            if shutOut {
                HStack {
                    Text("Shut Out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("500")
                        .font(.caption)
                        .fontDesign(.monospaced)
                }
            }
            Divider()
            HStack {
                Spacer()
                Text(totalScore.formatted(.number.grouping(.never)))
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }
}

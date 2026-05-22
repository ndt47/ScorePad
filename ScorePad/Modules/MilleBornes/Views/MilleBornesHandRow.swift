import SwiftUI

typealias PresentHand = (MilleBornesHand) -> Void

private struct PresentHandKey: EnvironmentKey {
    static let defaultValue: PresentHand = { _ in }
}

extension EnvironmentValues {
    var presentHand: PresentHand {
        get { self[PresentHandKey.self] }
        set { self[PresentHandKey.self] = newValue }
    }
}

// MARK: - Hand Row

struct MilleBornesHandRow: View {
    var hand: MilleBornesHand
    @Environment(\.presentHand) var present

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            TeamScoreColumn(score: hand.team1)
            TeamScoreColumn(score: hand.team2)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { present(hand) }
    }
}

struct MilleBornesHandRow_Previews: PreviewProvider {
    static var hand: MilleBornesHand {
        var h = MilleBornesHand()
        h.team1.cards100 = 6; h.team1.cards50 = 2
        h.team1.safeties = 2; h.team1.coupsFourres = 1
        h.team1.tripCompleted = true
        h.team2.cards100 = 3; h.team2.cards50 = 2
        h.team2.safeties = 1
        return h
    }

    static var previews: some View {
        ZStack {
            Rule(.vertical)
            MilleBornesHandRow(hand: hand)
                .padding(.vertical, 4)
        }
        .frame(height: 160)
        .padding(.horizontal)
    }
}

// MARK: - Team Score Column

struct TeamScoreColumn: View {
    var score: MilleBornesTeamScore

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if score.scoreLines.isEmpty {
                Text("—")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(score.scoreLines) { line in
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
                Divider()
                HStack {
                    Spacer()
                    Text(score.handScore.formatted(.number.grouping(.never)))
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .fontWeight(.bold)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }
}

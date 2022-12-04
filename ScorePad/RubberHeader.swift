import SwiftUI

struct RubberHeader: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            TeamView(team: .we)
            TeamView(team: .they)
        }
    }
}

struct TeamView: View {
    var team: Team
    @EnvironmentObject var rubber: Rubber

    var title: String {
        if case .we = team {
            return "We"
        }
        return "They"
    }
    var points: Int {
        let points = rubber.points(for: team)
        return points.above + points.below
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .trailing) {
                    Text(title)
                        .font(.title2)
                        .bold()
                    Text("\(points.formatted(.number.grouping(.never)))")
                        .font(.title3)
                        .fontDesign(.monospaced)
                        .foregroundColor(.gray)
                        .bold()
                }
                Divider()
                    .frame(height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(team.positions, id: \.self) {
                        PlayerView($0)
                    }
               }
            }
            Text(rubber.isVulnerable(team) ? "VULNERABLE" : "")
                .font(.caption)
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity)
        .rubber(rubber)
    }
}
        
struct RubberHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RubberHeader()
                .environmentObject(Rubber())
            Divider()
            RubberHeader()
                .environmentObject(Rubber.mock)
        }
    }
}

import SwiftUI

struct RubberHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            TeamView(team: .we)
            TeamView(team: .they)
        }
    }
}

struct TeamView: View {
    var team: Team
    @Environment(\.currentRubber) var rubber

    var title: String {
        if case .we = team {
            return "We"
        }
        return "They"
    }
    var subtitle: String {
        let positions = team.positions
        guard let first = rubber.player(at: positions.0), let last = rubber.player(at: positions.1) else {
            return "\(positions.0.label) & \(positions.1.label)"
        }
        return "\(first) & \(last)"
    }
    var points: Int {
        let points = rubber.points(for: team)
        return points.above + points.below
    }
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .bold()
            Text(subtitle)
                .font(.subheadline)
            Text("\(points.formatted(.number.grouping(.never)))")
                .font(.title3)
                .fontDesign(.monospaced)
                .bold()
        }
        .frame(maxWidth: .infinity)
    }
}
        
struct RubberHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RubberHeader()
                .environment(\.currentRubber, Rubber())
            RubberHeader()
                .environment(\.currentRubber, .mock)
        }
    }
}

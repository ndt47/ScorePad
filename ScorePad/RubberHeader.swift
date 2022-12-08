import SwiftUI

struct RubberHeader: View {
    @EnvironmentObject var rubber: Rubber
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            TeamView(team: .we)
            TeamView(team: .they)
        }
    }
}

struct TeamView: View {
    @EnvironmentObject var rubber: Rubber
    var team: Team

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
        VStack(alignment: .center) {
            HStack {
                VStack(alignment: .trailing) {
                    HStack {
                        Spacer()
                        Text(title)
                            .font(.title2)
                            .fontWeight(.heavy)
                            .allowsTightening(true)
                    }.frame(maxWidth: .infinity)
                    HStack {
                        Spacer()
                        Text("\(points.formatted(.number.grouping(.never)))")
                            .font(.title3)
                            .fontDesign(.monospaced)
                            .foregroundColor(.gray)
                   }.frame(maxWidth: .infinity)

                }
                .frame(alignment: .trailing)
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(team.positions, id: \.self) { p in
                        HStack {
                            PlayerView(position: p)
                            Spacer()
                        }.frame(maxWidth: .infinity)
                    }
                }.frame(maxWidth: .infinity).frame(alignment: .leading)
            }
            Text(rubber.isVulnerable(team) ? "VULNERABLE" : "")
                .font(.caption)
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RubberHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RubberHeader()
                .environmentObject(Rubber.mock)
            Divider()
            RubberHeader()
                .environmentObject(Rubber())
        }
    }
}

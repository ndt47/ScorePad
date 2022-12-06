//
//  RubberListCell.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/5/22.
//

import SwiftUI

struct RubberListCell: View {
    @StateObject var rubber: Rubber
    @Environment(\.selected) var selected
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    ForEach(Team.allCases, id: \.self) {
                        Text($0.label)
                    }
                }
                .fontWeight(.heavy)
                .frame(alignment: .leading)
                .lineLimit(1)
                .allowsTightening(true)

                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Team.allCases, id: \.self) { team in
                        let player1 = rubber.player(at: team.positions[0]) ?? team.positions[0].label
                        let player2 = rubber.player(at: team.positions[1]) ?? team.positions[1].label
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(player1) & \(player2)")
                            if rubber.winningTeam == team {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.orange)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .fontWeight(.light)
                .font(.subheadline)
                .lineLimit(1)
                .allowsTightening(true)

                Spacer()
                
                VStack(alignment: .trailing) {
                    ForEach(Team.allCases, id: \.self) {
                        Text("\(rubber.points(for: $0).total.formatted(.number.grouping(.never)))")
                    }
                }
                .fontDesign(.monospaced)
                .frame(alignment: .trailing)
            }

            HStack(alignment: .firstTextBaseline) {
                Text("Last played").bold()
                Text(rubber.lastModified.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.caption)
            .foregroundColor(selected ? .white : .gray)
        }
        .environmentObject(rubber)
    }
}


struct RubberListCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RubberListCell(rubber: .mock)
            RubberListCell(rubber: .mock)
                .selected(true)
        }
    }
}

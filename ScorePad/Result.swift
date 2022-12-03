//
//  Result.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/2/22.
//

import SwiftUI

struct Result: View {
    var value: Int
    var appearance: Appearance
    
    enum Appearance {
        case abbreviated, long
    }
    
    var body: some View {
        switch value {
        case 0:
            Image(systemName: "checkmark")
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(.green)
        default:
            if case .abbreviated = appearance {
                Text("\(value.formatted(.number.sign(strategy: .always())))")
                    .foregroundColor(.gray)
                    .fontDesign(.monospaced)
            } else {
                Text("\(value < 0 ? "Down" : "Up")  \(value.magnitude)")
                    .foregroundColor(.gray)
            }
        }
    }
    
    init(_ value: Int, _ appearance: Appearance = .abbreviated) {
        self.value = value
        self.appearance = appearance
    }
}

struct Result_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Result(0)
            Result(-1)
            Result(3)
            Result(-3)
            Result(0, .long)
            Result(-1, .long)
            Result(3, .long)
            Result(-3, .long)

        }
    }
}
